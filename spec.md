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
		static page "acme coffee": index.html, style.css, app.js, no build step
		owns the git repo `shared/webapp.git`, serves it over `git://webapp/webapp.git`
		nginx serves `shared/site`, a checkout of main refreshed every 2 s
		injects a live-reload script so open tabs refresh after each publish

task lifecycle
	columns: new, to do, in progress, need review, done
	new task lands in new
	human drags a card to to do when it should be built
	bridge picks the oldest to do card, one run at a time
		all runs edit the same repo
	bridge launches a framework run
		flow `webapp-change@1.0`, feature request = task text + reporter + time
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
	implement - ai node
		edit the static site to fulfil the task, smallest change, no frameworks or cdn
		write change-summary.md as a run artifact
	smoke-check - command node
		index.html exists and is well terminated
	finish - terminal
		shared by success and failure
		failure reaches it as implicit failure: run ends failed, publish skipped
	publish: framework commits as hgsdlc-bot and pushes to main of the webapp repo

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

scope decisions for the prototype
	skip spec-driven artifacts
		no per-task delta spec
		no master spec
		only run-scoped change-summary.md, visible in the framework ui
		framework supports it via openspec flow and skills in its catalog, left for later
	no human approval gate in the flow, runs are fully automatic
		human control is the manual move to to do and the need review column

persistence
	all state on disk in `./shared`
		webapp.git - web app code and history
		site - what nginx serves
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

operations
	make start - build if needed, start, wait for framework setup, open the three tabs
	make stop - stop containers, keep containers and data
	make restart - stop + start, nothing lost
	make reset - asks for confirmation, removes containers and wipes all data
	make open, make status, make logs - helpers
