# Open Data: AI-Generated versus Human Supervisor Feedback on Medical Students' Clinical Clerkship Logs

This repository contains the anonymized evaluation data and analysis code for:

> Kondo T, Donkers J, Nishigori H, Rovers S, Heeneman S. AI-generated versus human supervisor feedback on medical students' clinical clerkship logs: convergent mixed methods study. *JMIR Medical Education*. (under review)

## Repository Structure

```
data/
  quantitative/
    data.csv                      # Rubric evaluation scores (tidy format)
  qualitative/
    text_and_code_en_anon.csv     # Anonymized evaluator comments with qualitative codes
    code_list_en.csv              # Qualitative codes with supporting text
    theme_and_code_en.csv         # Theme-code hierarchy
    theme_table_en.csv            # Summary theme table
analysis/
  quantitative/
    prepare_quantitative_data.r   # Data preprocessing script
    quantitative.qmd              # Main quantitative analysis (Quarto)
    additional_analyses.qmd       # Additional analyses for revision
  qualitative/
    extract_theme_analysis_data.r # Qualitative data extraction and coding
  integration/
    joint_display_analysis.md     # Mixed methods joint display analysis
```

## Data Description

### Quantitative Data (`data/quantitative/data.csv`)

Rubric-based evaluation scores comparing AI-generated and human supervisor feedback on clinical clerkship logs. Each row represents one evaluator's score on one rubric item for one feedback pair.

| Column | Description |
|--------|-------------|
| ID | Evaluation session identifier |
| time | Timestamp of evaluation |
| assessor_type | Evaluator role (faculty or student) |
| feedback_provider | Anonymized feedback provider ID |
| student | Anonymized student ID |
| assessor | Evaluator number |
| record_id | Clinical log record ID |
| unmatch | Whether feedback provider matched the log's supervisor (0 = match, 1 = unmatch) |
| department | Clinical department (English) |
| log_letter_count | Character count of the clinical log |
| log_date_count | Number of dates in the clinical log |
| log_id | Unique log identifier |
| item | Rubric dimension (criteria.based, clear.direction, accurate, prioritization, supportive) |
| person | Feedback source (ai, supervisor) |
| value | Score (1-5 Likert scale) |
| feedback_letter_count | Character count of the feedback text |

### Qualitative Data (`data/qualitative/`)

- **text_and_code_en_anon.csv**: Evaluator free-text comments (English translation) with assigned qualitative codes. IDs are anonymized sequential identifiers.
- **code_list_en.csv**: List of qualitative codes with all supporting evaluator comments grouped by code.
- **theme_and_code_en.csv**: Hierarchical mapping of themes, sub-themes, and codes from thematic analysis.
- **theme_table_en.csv**: Summary table of themes, sub-themes, and associated codes per feedback provider (AI/supervisor).

## Privacy and Ethics

- Original clinical clerkship logs are **not** included because they may contain personally identifiable information about medical students. Public release would exceed the scope of consent obtained through the opt-out procedure approved by the ethics committee.
- Supervisor feedback texts are **not** included to prevent potential identification of individual supervisors.
- All identifiers have been replaced with anonymous sequential IDs.
- The study was approved by the Institutional Review Board of Nagoya University Graduate School of Medicine.

## Analysis

The analysis scripts document the analytical process but may not run independently in this repository, as some depend on the full project environment (renv, Google Sheets authentication). They are provided for transparency and reproducibility reference.

## License

This dataset is made available under the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license.

## Contact

Takeshi Kondo (ncukondo@gmail.com)
Center for Medical Education, Nagoya University Graduate School of Medicine
