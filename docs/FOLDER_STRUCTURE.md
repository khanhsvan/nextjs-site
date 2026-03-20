# Folder Structure

```text
.
|-- apps
|   |-- api
|   |   `-- src
|   |       |-- common
|   |       `-- modules
|   |-- web
|   |   |-- app
|   |   |-- components
|   |   `-- lib
|   `-- worker
|       `-- src
|-- docs
|   |-- API.md
|   `-- FOLDER_STRUCTURE.md
|-- infra
|   |-- docker
|   |-- nginx
|   `-- sql
`-- packages
    |-- config
    `-- types
```

## Key Responsibilities

- `apps/api`: auth, catalog, playback authorization, subscriptions, analytics, admin APIs
- `apps/api`: also contains compliance, legal policy, license verification, and access logging middleware
- `apps/web`: customer-facing experience, account, custom player, admin dashboard
- `apps/worker`: transcoding and background processing
- `packages/types`: shared contracts and enums
- `packages/config`: access logic and shared platform constants
