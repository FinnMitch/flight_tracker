```mermaid
graph TD
    A[load & parse csv] --> C[store //ArrayList]
    C -->|query select| D[filter data]
    D --> E[display]
    E --> F[user input]
    F -- Change Query --> D
```

    