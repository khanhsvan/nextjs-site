# Install Guide For New Users

This guide is written for someone who is not technical.

## What this app does

This project is a video streaming platform with:
- user accounts
- admin dashboard
- video streaming from a private storage server
- legal pages, DRM-style token protection, and copyright tools

## Before you start

You need these 3 things on your Windows computer:

1. `Docker Desktop`
   Download: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

2. `A private storage server URL`
   Example: `http://storage.internal:8080` or `http://xxx.xxx.xxx.xxx`

3. `Internet access the first time`
   Docker needs to download containers the first time you run the system.

## Step 1: Open the project folder

Make sure this project folder exists on your computer:

`D:\NetBeansProjects\webtruyen\webphim`

## Step 2: Start Docker Desktop

Open Docker Desktop and wait until it says Docker is running.

Do not continue until Docker is fully started.

## Step 3: Prepare the storage server settings

Open the `.env` file and set:

- `STORAGE_BASE_URL`
- `STORAGE_AUTH_TYPE`
- `STORAGE_SECRET`
- `STORAGE_PROXY_MODE`

Your storage server should already contain HLS files such as:

- `/videos/movie1/index.m3u8`
- `/videos/movie1/segment001.ts`
- `/videos/series1/index.m3u8`

## Step 4: First-time setup

Double-click this file:

`RUN_PLATFORM.bat`

On the first run, it will:
- create a `.env` file if missing
- start all services with Docker

The platform reads settings from `.env`.

## Step 5: Open the app

After startup, use these links:

- Web app: [http://localhost:3000](http://localhost:3000)
- API: [http://localhost:4000/health](http://localhost:4000/health)
- Email test inbox: [http://localhost:8025](http://localhost:8025)

## First login notes

This project currently contains demo/sample backend logic and UI scaffolding.

If you are testing:
- use the public pages without login
- open admin pages with the current demo flow
- use sample video IDs like `vid_movie_1`

## If videos do not play

Check these items:

1. Docker Desktop is running
2. `STORAGE_BASE_URL` points to the correct private server
3. The storage server contains HLS files like `index.m3u8`
4. The file paths inside playlists are valid

## If the app does not start

Try this:

1. Close all app windows
2. Re-open Docker Desktop
3. Double-click `RUN_PLATFORM.bat` again

If it still fails, open Command Prompt in the project folder and run:

```bat
docker compose -f infra\docker\docker-compose.yml up --build
```

## To stop the platform

Open Command Prompt in the project folder and run:

```bat
docker compose -f infra\docker\docker-compose.yml down
```

## Important file to edit later

If you need to change ports, storage URL, or secrets, edit:

`D:\NetBeansProjects\webtruyen\webphim\.env`
