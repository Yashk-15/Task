# ProjectFlow web app

This responsive React + TypeScript client talks to the Project Management REST API. It contains no backend or database logic.

## Run locally

1. Copy `.env.example` to `.env`.
2. Set `VITE_API_URL` to your API URL, including `/api`.
3. From this `web` folder, run `npm run dev`.
4. Open the local address shown by Vite (normally `http://localhost:5173`).

## Environment variables

`VITE_API_URL` is the base URL for the API. For example, use `http://localhost:3000/api` locally or `https://your-api.onrender.com/api` after deployment.

## Deploy to Vercel

Import this repository in Vercel and set the project root directory to `web`. Add `VITE_API_URL` in Vercel's Environment Variables, then deploy. `vercel.json` rewrites browser routes to `index.html`, so refreshing a URL such as `/projects/123` works correctly.
