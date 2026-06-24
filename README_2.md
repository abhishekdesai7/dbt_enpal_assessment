Enpal - Analytics Engineering Case Study - June 2026

List on Contents:
1. Business Context
2. Key Business Questions and Metrics
3. Solution Architecture
4. Data Quality Findings & Assumptions
5. Key Architectural Decisions and Data Quality Checks
6. Future Improvements

1. Business Context

Pipedrive is CRM platform used by Enpal to manage customer opportunities throughout the sales lifecycle. 
Deals move through a series of sales stages and are supported by activities performed by employees. This project focuses on building a scalable analytics layer that enables sales funnel reporting, stage conversion analysis, lost deal insights, and employee activity reporting. The proposed solution follows a layered dbt architecture consisting of staging, intermediate, dimensional, fact and reporting layers designed for scalability and maintainability.

2. Key Business Questions

Business use cases:

    a. How are deals progressing through the sales funnel?
    b. Which stages have the highest customer drop-off?
    c. What are the primary reasons for lost deals?
    d. How are employee activities distributed across deals and stages?

Key Metrics: 
    1. Deal volume by stage (Reporting table)
    2. Lost deals by reason
    3. Activity volume by employee and activity type
    4. Stage Conversion Rate

3. Solution Architecture

Raw Pipedrive Sources
(deals, deal_changes, activities,
 activity_types, users, stages, fields)
                │
                ▼

        Staging Layer
          (Views)
                │
                ▼

      Intermediate Layer
  • Deal stage transitions
  • Employee history
  • Activity deduplication
                │
                ▼

      Dimensional Layer

Dimensions:
• tbl_dim_deal
• tbl_dim_stage
• tbl_dim_activity_type
• tbl_historical_dim_employee (SCD-II)

Facts:
• tbl_fact_deal
• tbl_fact_deal_stage_transition
• tbl_fact_activity
                │
                ▼

        Reporting Layer
      • tbl_report_sales_funnel
    
(Refer to Architecture_design.png diagram for detailed lineage.)

4. Data Quality Findings & Assumptions

Data Profiling Insights
| Table                |   Rows | Purpose                                                                     | Primary Key Candidate                                                             |
| -------------------- | -----: | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------|
| `activity.csv`       |  4,579 | Sales activities performed against deals                                    | activity_id                                                                       |
| `deal_changes.csv`   | 15,406 | Audit trail of deal field changes, stage transitions, and ownership changes | No single PK identified; likely deal_id, change_time, changed field_key.          |
| `users.csv`          |  1,787 | CRM users / sales agents / internal employees                               | employee_id (id)                                                                  |
| `stages.csv`         |      9 | Sales pipeline stage definitions                                            | stage_id                                                                          |
| `activity_types.csv` |      4 | Lookup table for activity categories                                        | activity_type_id (id)                                                             |
| `fields.csv`         |      4 | Metadata describing CRM custom fields                                       | id                                                                                |


Data Quality Findings
| Observation                                                      | Solution                                    |
| ---------------------------------------------------------------- | ------------------------------------------- |
| Duplicate activity records exist in source data                  | Deduplicated in the intermediate layer      |
| Duplicate stage transitions exist for some deals                 | Consecutive duplicate stages are removed    |
| Multiple users can act on same deal within overlapping timeframe | First ownership is retained                 |
| User emails are not unique and cannot be used as business keys   | user_id is used as the primary identifier   |
| Employee active/inactive history is unavailable                  | Historical status tracking not implemented  |
| Activity type validity periods are unavailable                   | Only Current state is retained              |
| deal_changes and activity ownership records do not always align  | Added as documented data quality limitation |
| Fields table is largely disconnected from analytical use cases   | Excluded from marts                         |

Key Assumptions
    1. Source data currently contains lost deals only, however the model is designed to support open and won deals.
    2. Deals may move backwards through the funnel if reopened.
    3. A deal moving to further stages is not assumed to have passed through skipped stages.
    4. tbl_fact_deal and tbl_dim_deal contain one record per deal using the first deal creation timestamp and first recorded lost reason.
    5. Stage IDs greater than 6 are treated as valid business states. Assumption is that customers are allowed to reneg on the deal post closing stage, however needs business validation.
    6. user_id and assigned_to_user are assumed to be same and represent employees responsible for the deal.

5. Key Architectural Decisions and Data Quality Checks

| Decision                                                             | Rationale                                        |
| -------------------------------------------------------------------- | ------------------------------------------------ |
| Staging and intermediate models are materialized as views            | Minimize storage and simplify transformations    |
| tbl_fact_deal and tbl_dim_deal use incremental merge strategy        | Efficient processing of new and updated records  |
| Remaining marts are materialized as tables                           | Current data volumes are small                   |
| Reporting tables are built from dimensions and facts                 | Ensures a single source of truth                 |
| All source tables are enriched with source_system_code = 'Pipedrive' | Enables future cross-domain source integration   |
| historical_dim_employee is modeled as SCD-II                         | Preserves employee history and ownership changes |
| Marts are organized by business domain                               | Improves discoverability and maintainability     |
| Selected dbt tests use warning severity                              | Known source issues should not block reporting   |

Data Quality Checks
The following dbt tests were implemented across the transformation layers:

    1. Uniqueness tests on primary business keys
    2. Not-null tests on critical reporting fields
    3. Accepted value or referential integrity tests on reference dimensions
    4. Warning-level tests for known source data quality issues

6. Future Improvements
    1. Convert reporting and event-based fact tables to incremental models as data volume grows.
    2. Evaluate SCD-II tracking for stages and activity types if historical reporting becomes a requirement.
    3. Capture activity completion timestamps to support SLA and conversion analysis.
    4. Consider storing deal stage history in a nested structure within fact_deal while maintaining flattened reporting models.
    5. Utilize doc blocks for repeated attributes and consistency.

Tech Stack - dbt, PostgreSQL, SQL, GitHub