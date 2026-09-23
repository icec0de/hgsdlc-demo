FROM python:3.12-alpine
WORKDIR /app
COPY app.py index.html seed-tasks.json ./
EXPOSE 8081
CMD ["python", "-u", "app.py"]
