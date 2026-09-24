````
task
	demonstrate human guided sdlc end to end: human intent in a task tracker becomes a live change in a client-facing web app
	framework: human guided sdlc (hg sdlc), open source, gitverse.ru/kakvsbere/hgsdlc
	audience watches three safari tabs
		task board - where intent is expressed
		framework ui - observability of the run
		web app - the client-facing result, changes live
	keep everything as simple as possible
	example intents
		```
		add a "contact us" button next to "order now"
		change the color of the order button to green
		change default language and text to russian
		```

components
	three docker containers, one shared folder `./shared`
	taskboard - http://localhost:8081
		primitive kanban board, python stdlib only
		task fields
			reporter
			task - free text, becomes the prompt (feature request)
			date and time
		bridge to the framework runs inside the same container
	framework - http://localhost:8080, admin / admin
		hg sdlc built from source: backend and ui in one jar
		coding agent cli installed in the same image
		configured on start through its own rest api by `setup.sh`
	webapp - http://localhost:8082
		static page (starts as "acme coffee", a fictional coffee shop), index.html/style.css/app.js, no build step
		owns the git repo `shared/webapp.git`, serves it over `git://webapp/webapp.git`
		nginx serves `shared/site`, a checkout of main refreshed every 2 s
		injects a live-reload script so open tabs refresh after each publish

task lifecycle
	every task gets a unique sequential id, T-0001
	jira-like board ux
		card footer: task type icon, key (struck through when done), date, reporter avatar
		click a card: issue view
			summary, status lozenge, reporter, created, resolved, run link, run stats, validation
			tabs: delta spec, validation, master spec after - rendered from shared/specs
		deep link: http://localhost:8081/#T-0005
	columns: new, to do, in progress, need review, done
	new task lands in new
	human drags a card to to do when it should be built
	bridge picks the oldest to do card, one run at a time
		all runs edit the same repo
	bridge launches a framework run
		flow `webapp-sdd`, whichever version the framework has published, feature request = task text + id + reporter + time
		publish mode direct push to main
	card moves to in progress, links to the run in the framework ui
	run completed and published -> done
	run failed -> need review, with error code, nothing published
	run lost (framework data gone) -> need review
	human moves
		need review -> to do: retry, previous run is forgotten
		need review -> done: accept
		in progress is owned by the framework, no manual moves in or out
	done and need review cards show run stats
		duration from framework start/finish times
		tokens: total, input including cached, output
			framework reports cached input separately, it is ~99% of input
	tab order: task -> add task, so tab + space submits
		button has explicit tabindex, safari skips buttons otherwise

framework flow
	flow `webapp-sdd`, spec-driven with tests and governance
	run env set by the board
		TASK_ID - unique sequential id, T-0001
		TASK_DIR - spec folder name = task id only, T-0001
	prepare - command node
		create specs/ and tests/, seed specs/governance.md if missing
		gitignore .hgsdlc/ and test-results/: runtime scratch never gets published
		logic lives in /app/checks/prepare.sh
			framework runs a command in the run folder, not the repo, if its text mentions `.hgsdlc/`
	ai nodes retry once on transient failures
		artifact or step summary missing, agent error, acp timeout
		```
		T-0006 failed: Required produced artifact missing: change-summary.md
		agent wrote it into the repo (main/.hgsdlc/...) instead of the run folder
		fix: retry policy, drop the redundant change-summary.md artifact
		```
	specify - ai node
		if specs/master.md is missing: write a baseline from the current code
			recorded as T-0000
		write the delta spec specs/changes/<TASK_DIR>/delta.md
			what changes, not how
			added / modified / removed requirements with when-then scenarios
			must respect governance, scenarios must be observable in a browser
	write-tests - ai node, before implementation
		one playwright test per delta scenario: tests/<TASK_ID>.spec.js
		test title = "<TASK_ID>: <scenario name>", verbatim
	implement - ai node
		implement exactly the delta spec, make its tests pass, follow governance
		must not touch specs/ or tests/
	validate - command node, deterministic, code lives in the framework image
		run all tests: this task's scenarios, every earlier task's (regression), governance tests
		check every principle of specs/governance.md
		write specs/changes/<TASK_DIR>/validation.md and validation.json
		any failed principle fails the run
	merge-spec - ai node
		apply the delta to specs/master.md
		set last increment, append one line to the increments log
	record-increment - command node
		check master names the task id and the validation record exists
		snapshot master to specs/changes/<TASK_DIR>/master.md
	finish - terminal
		shared by success and failure
		failure reaches it as implicit failure: run ends failed, publish skipped
		no code, spec or tests from a failed run
	publish: one commit by hgsdlc-bot with code, tests and specs, pushed to main
	the framework assigns its own version on publish (1.0, 1.1, ...)
		independent of whatever "version:" the yaml itself declares
		```
		bug: board hardcoded flow_canonical_name "webapp-sdd@5.0" (the yaml's own version)
		every fresh install actually published as "webapp-sdd@1.0" - the framework's number, not ours
		every task failed: POST /runs -> 404 Flow not found: webapp-sdd@5.0
		found while taking screenshots for the readme on a freshly reset install
		fix: board looks up the published canonical_name by flow_id at run time,
		same pattern already used to resolve project_id by name
		```

governance and validation
	principles: specs/governance.md in the web app repo, human-owned
		```
		G-01 the page is always in russian: html lang="ru", >= 80% cyrillic visible text
		G-02 no external frameworks, scripts or stylesheets
		G-03 every delta scenario has a passing test
		G-04 existing behaviour keeps working: all earlier tasks' tests pass
		G-05 spec before code: delta before implementation, merged into master after
		```
	checks are enforced by the framework, not by the ai
		validate.sh, governance tests and playwright config live in the framework image
		the ai cannot edit the checker; it only writes the scenario tests
	ai writes the tests from the delta scenarios
		risk: a weak test passes; limited by g-03 scenario coverage and g-04 regression
	per-task record: what should apply, what was applied, how it was validated
		validation.md - table principle / result / evidence + list of tests
		validation.json - same, read by the task board
	done cards show tests passed/total and each principle ✓ / ✗
	playwright + headless chromium in the framework image, about +400 mb
	tests are served by a tiny static server inside the framework container
	test scratch output stays in /tmp, never in the repo

specs
	stored in the web app repo under specs/, versioned with the code
	mirrored read-only to the host: shared/specs, open in finder
	never served by the public site
	spec folders are named by task id only, no feature description
	layout
		```
		specs/
			governance.md                      principles every task is validated against
			master.md                          current master spec + increments log
			changes/
				T-0000/master.md                   baseline
				T-0005/
					delta.md                       the task's delta spec
					validation.md                  principles, results, evidence, tests
					validation.json                same, machine-readable
					master.md                      master right after this increment
		tests/
			T-0005.spec.js                     scenario tests, kept as regression suite
		```
	tests and specs are not served by the public site
	every successful task = one increment = one folder, sorted by id
	fresh install seeds the app as it stood after the recorded demo (post t-0006), not the original acme coffee baseline
		the original baseline is kept as history only, in specs/changes/T-0000/master.md

technical design choices
	orbstack as the docker runtime instead of docker desktop
		the mac had no docker; light, installed via homebrew
		docker cli lives in ~/.orbstack/bin, makefile adds it to path
	llm: glm 5.3 through openrouter
		model id `z-ai/glm-5.3`, set by MODEL in .env
		key OPENROUTER_API_KEY in .env, never committed
	coding agent: opencode instead of qwen code
		issue
			stock hg sdlc image ships qwen code cli
			framework takes the model from the list the agent reports over acp
			qwen offered only its own `coder-model(qwen-oauth)`
			framework silently fell back to it, runs failed
			```
			ACP_REQUEST_FAILED: ACP agent error -32603: Internal error
			Qwen OAuth credentials expired. Please use /auth to re-authenticate with qwen-oauth.
			```
		solution
			install opencode cli in the framework image, launch `opencode acp`
			opencode reads OPENROUTER_API_KEY natively, lists `openrouter/z-ai/glm-5.3`
			setup warns if the configured model is missing from the agent's list
	git hosting: git daemon in the webapp container, no github/gitea
		framework requires an scm provider whose host matches the repo url
		placeholder provider `demo-git` (gitea type, host `webapp`, dummy token)
		framework applies credentials only to http(s) remotes, git:// needs none
	flow published at team scope
		organization scope publishes through a git catalog and pr, with no self-approval
		team scope published by admin goes straight to the framework db
	bridge talks to the framework ui api as admin (session token)
	framework ui served by the backend jar, no separate frontend container

scope decisions
	prototype v1 skipped spec-driven artifacts
		only a run-scoped change-summary.md
		replaced by the spec-driven flow: delta spec per task, merged into a master spec
	goal was to demonstrate how the framework operates, not to reconstruct openspec precisely
		spec format borrows openspec vocabulary because it is a good, known vocabulary
		process and rigor were kept light on purpose, see comparison below
	no human approval gate in the flow, runs are fully automatic
		human control is the manual move to to do and the need review column
		this is the main place this workflow is NOT human-guided in the openspec sense, see below

relationship to openspec
	close to openspec: spec format and vocabulary
		specs/master.md as source of truth, specs/changes/<id>/delta.md as a delta
		delta sections ADDED / MODIFIED / REMOVED Requirements (RENAMED is not used)
		### Requirement: ... SHALL ..., #### Scenario: ... WHEN / THEN, same wording
		MODIFIED repeats the full new text of the requirement, same rule as openspec
		archive-like step: merge-spec + record-increment merges the delta and snapshots master
		baseline spec (T-0000) generated once from the pre-existing app, like adopting openspec on a brownfield repo
	far from openspec: process
		openspec's core discipline is agreeing the delta BEFORE code is written
			human reads proposal.md + delta, approves or asks for changes, then implementation starts
		this workflow only gets human sign-off on the one-line intent (drag to to do)
			specify, write-tests, implement all run inside the same automatic pass
			delta.md ends up documenting what the ai decided, not what a human agreed to
		no proposal.md (why) or design.md (how) or tasks.md (checklist), only delta.md (what)
		merge-spec is done by an ai rewriting master.md, not a deterministic header-based merge
			openspec archive merges mechanically by requirement name
			risk: the model could reword or drop an untouched requirement, only checked by task id presence
		one master.md instead of one spec file per capability
		no spec structure validation (openspec validate --strict equivalent)
	beyond openspec: verification this workflow adds
		every scenario becomes a playwright test before implementation, kept as a regression suite
		specs/governance.md is a constitution (spec-kit idea) enforced by code the ai cannot edit
		validation.md / validation.json record, per task, which principles applied and how they were checked
		task ids link the tracker, the spec folder, the tests and the commit git history one to one
	verdict
		spec format and merge idea: close to openspec
		process discipline (approve-before-code): not followed, by choice, for this prototype
		verification (tests, governance, evidence): goes beyond what openspec itself defines
		to make it more openspec-like: add a human approval gate on the delta before write-tests /
		implement, and replace the ai merge with a deterministic one; deliberately left undone here

persistence
	all state on disk in `./shared`
		webapp.git - web app code, specs and history
		site - what nginx serves
		specs - read-only mirror of specs/ on main
		board/tasks.json - cards and stats
		framework/db - framework h2 database file
		framework/workspace - run workspaces, agent logs, artifacts
	framework switched from in-memory db to h2 file
	setup is idempotent
		settings re-applied on every start, .env changes take effect
		flow, scm provider, project created only when missing
		changing the flow requires a new version
	survives stop, restart and image rebuilds, including run history and run links
	wipe only on purpose

demo seed data
	goal: a fresh git clone runs exactly like the recorded demo, no setup steps to see the point
	seeded once, only when ./shared does not exist yet (first start, or after make reset)
		never overwrites a board or web app a human has since changed
	taskboard/seed-tasks.json - the 6 completed tasks (t-0001..t-0006) plus 2 pending ones, verbatim
		copied from the live board's tasks.json at the end of the recorded session
		stats and validation are read from specs at request time, not duplicated in the seed
	webapp/site/ - the web app's git seed brought up to the state after t-0006
		index.html / style.css / app.js / readme.md as published
		specs/ - governance.md, master.md, every specs/changes/<id>/ folder produced so far
		tests/ - the ai-written playwright tests for t-0005 and t-0006
	seeded run links (open run ↗) point at the original run ids from the recording
		they 404 against a fresh framework - same as any run lost to a framework reset, not a bug

operations
	make start - build if needed, start, wait for framework setup, open the three tabs
	make stop - stop containers, keep containers and data
	make restart - stop + start, nothing lost
	make reset - asks for confirmation, removes containers and wipes all data
	make open, make status, make logs - helpers
````
