# Load libraries using pacman
if (!require(pacman)) install.packages("pacman")
pacman::p_load(
  tidyverse,
  dplyr,
  ggplot2,
  readr,
  stringr,
  rio,
  here,
  googlesheets4,
  purrr,
  dotenv
)

# Load environment variables from .env
dotenv::load_dot_env(here::here(".env"))

# Authenticate with Google Sheets (will prompt for authentication)
# gs4_auth()

# Read from Google Spreadsheet and save as Excel file
ss_id <- Sys.getenv("QUALITATLVE_DATA_SHEET_ID")

# Get all sheet names
sheet_names <- sheet_names(ss_id)

# Create a list to store all sheets data
sheets_data <- list()

# Read each sheet and store in the list
for (sheet in sheet_names) {
  sheets_data[[sheet]] <- read_sheet(ss_id, sheet = sheet)
}

# Save as Excel file
rio::export(sheets_data, here("data", "qualitative", "raw.xlsx"))

# Extract individual sheets from the list
translation_data <- sheets_data$theme_translation

raw_data <- sheets_data$raw |>
  mutate(
    AI_ID = paste0("AI_", AI_LINK),
    SU_ID = paste0("SU_", SUPERVISOR_LINK)
  ) |>
  select(-AI_LINK, -SUPERVISOR_LINK)

ai_data <- sheets_data$ai |>
  mutate(
    ID = paste0("AI_", AI_LINK),
    provider = "AI"
  ) |>
  select(-AI_LINK) |>
  rename(
    feedback = comment_ai,
    feedback_en = comment_ai_en
  ) |>
  left_join(
    raw_data |>
      select(AI_ID, starts_with("source_")),
    by = c("ID" = "AI_ID")
  ) |>
  rename(source_feedback = source_feedback_ai) |>
  select(-source_feedback_supervisor)

supervisor_data <- sheets_data$supervisor |>
  mutate(
    ID = paste0("SU_", supervisor_link),
    provider = "supervisor"
  ) |>
  select(-supervisor_link) |>
  rename(
    feedback = comment_supervisor,
    feedback_en = comment_supervisor_en
  ) |>
  left_join(
    raw_data |>
      select(SU_ID, starts_with("source_")),
    by = c("ID" = "SU_ID")
  ) |>
  rename(source_feedback = source_feedback_supervisor) |>
  select(-source_feedback_ai)

theme_data <- sheets_data$theme |>
  mutate(provider = case_when(
    str_starts(id, "AI") ~ "AI",
    str_starts(id, "HU") ~ "supervisor",
    TRUE ~ "other"
  )) |>
  left_join(
    translation_data |>
      filter(category == "sub_theme") |>
      select(ja, en),
    by = c("sub_theme" = "ja")
  ) |>
  rename(sub_theme_en = en) |>
  left_join(
    translation_data |>
      filter(category == "theme") |>
      select(ja, en),
    by = c("theme" = "ja")
  ) |>
  rename(theme_en = en) |>
  mutate(category = case_when(
    category == "po" ~ "positive",
    category == "ne" ~ "negative",
    category == "flat" ~ "neutral",
    TRUE ~ "other"
  )) |>
  mutate(
    category = factor(
      category,
      levels = c("positive", "neutral", "negative", "other")
    )
  ) |>
  arrange(category)


# Combine ai_data and supervisor_data vertically
text_and_code <- bind_rows(ai_data, supervisor_data) |>
  mutate(code = code2) |>
  select(ID, provider, code, code_en, feedback, source_feedback, everything())

# Save text_and_code as CSV with UTF-8-BOM encoding
text_and_code |>
  readr::write_excel_csv(here("data", "qualitative", "text_and_code.csv"), na = "")

# Create text_and_code_en with selected columns only
text_and_code |>
  select(ID, provider, assessor_type, feedback_en, code_en) |>
  rename(
    Provider = provider,
    Code = code_en,
    Text = feedback_en
  ) |>
  readr::write_excel_csv(here("data", "qualitative", "text_and_code_en.csv"), na = "")

# Create anonymized text_and_code_en for open data repository
# - Replace original IDs with sequential anonymous IDs per provider
# - Remove assessor_type to prevent cross-referencing
text_and_code |>
  select(ID, provider, feedback_en, code_en) |>
  arrange(provider, ID) |>
  group_by(provider) |>
  mutate(anon_id = paste0(
    ifelse(provider == "AI", "AI", "SU"),
    "_",
    sprintf("%03d", row_number())
  )) |>
  ungroup() |>
  select(anon_id, provider, feedback_en, code_en) |>
  rename(
    ID = anon_id,
    Provider = provider,
    Text = feedback_en,
    Code = code_en
  ) |>
  readr::write_excel_csv(here("data", "qualitative", "text_and_code_en_anon.csv"), na = "")

# Create code_list grouped by code with text column containing ID:feedback
code_list <- text_and_code |>
  select(ID, provider, code, code_en, everything()) |>
  mutate(
    code = str_split(code, "/"),
    code_en = str_split(code_en, "/")
  ) |>
  unnest_longer(c(code, code_en), indices_include = FALSE) |>
  mutate(
    feedback = str_replace_all(feedback, "\\n", ""),
    feedback_en = str_replace_all(feedback_en, "\\n", " ")
  ) |>
  group_by(code, provider) |>
  summarise(
    code_en = first(code_en),
    text = paste(paste0("- ", ID, ":", feedback), collapse = "\n"),
    text_en = paste(paste0("- ", ID, ":", feedback_en), collapse = "\n"),
    refs = list(unique(ID)),
    .groups = "drop"
  )

# Save code_list as CSV with UTF-8-BOM encoding
code_list |>
  mutate(refs = map_chr(refs, ~ paste(.x, collapse = ", "))) |>
  readr::write_excel_csv(here("data", "qualitative", "code_list.csv"), na = "")

code_list_en <- code_list |>
  select(provider, code_en, text_en, refs) |>
  rename(
    Code = code_en,
    Text = text_en
  )

code_list_en |>
  mutate(refs = map_chr(refs, ~ paste(.x, collapse = ", "))) |>
  readr::write_excel_csv(here("data", "qualitative", "code_list_en.csv"), na = "")

# Join theme_data with code_list by code
theme_and_code <- theme_data |>
  left_join(code_list, by = c("code", "provider")) |>
  filter(!is.na(theme))

# Save theme_and_code as CSV with UTF-8-BOM encoding
theme_and_code |>
  mutate(refs = map_chr(refs, ~ paste(.x, collapse = ", "))) |>
  readr::write_excel_csv(here("data", "qualitative", "theme_and_code.csv"), na = "")

theme_and_code_en <- theme_and_code |>
  select(provider, category, theme_en, sub_theme_en, code_en, text_en, refs) |>
  rename(
    Theme = theme_en,
    Sub_Theme = sub_theme_en,
    Code = code_en,
    Text = text_en
  )

theme_and_code_en |>
  mutate(refs = map_chr(refs, ~ paste(.x, collapse = ", "))) |>
  readr::write_excel_csv(here("data", "qualitative", "theme_and_code_en.csv"), na = "")

# Create a comprehensive hierarchical structure with proper nesting
theme_analysis_markdown <- theme_and_code |>
  arrange(theme, provider, category, sub_theme, code) |>
  group_by(theme) |>
  group_split() |>
  map_chr(function(theme_group) {
    theme_header <- paste0("\n## Theme: ", first(theme_group$theme), "\n\n")

    provider_content <- theme_group |>
      group_by(provider) |>
      group_split() |>
      map_chr(function(provider_group) {
        provider_header <- paste0("\n### Provider: ", first(provider_group$provider), "\n\n")

        category_content <- provider_group |>
          group_by(category) |>
          group_split() |>
          map_chr(function(category_group) {
            category_header <- paste0("\n#### Category: ", first(category_group$category), "\n\n")

            sub_theme_content <- category_group |>
              group_by(sub_theme, sub_theme_en) |>
              group_split() |>
              map_chr(function(sub_group) {
                sub_name <- first(sub_group$sub_theme)
                sub_header <- paste0("- SubTheme: ", sub_name, "\n")

                codes_content <- sub_group |>
                  group_by(code, code_en) |>
                  group_split() |>
                  map_chr(function(code_group) {
                    code_name <- first(code_group$code)
                    code_en_name <- first(code_group$code_en)
                    code_line <- paste0("    - Code: ", code_name, "\n")

                    # Prepare associated text lines, indent each line
                    raw_text <- code_group |>
                      filter(!is.na(text) & nzchar(text)) |>
                      pull(text) |>
                      paste(collapse = "\n")

                    text_block <- ""
                    if (nzchar(raw_text)) {
                      text_lines <- str_split(raw_text, "\n") |> unlist()
                      indented <- paste0("        ", text_lines)
                      text_block <- paste0(indented, collapse = "\n")
                      text_block <- paste0(text_block, "\n")
                    }

                    paste0(code_line, text_block)
                  }) |>
                  paste(collapse = "")

                paste0(sub_header, codes_content)
              }) |>
              paste(collapse = "")

            paste0(category_header, sub_theme_content)
          }) |>
          paste(collapse = "")

        paste0(provider_header, category_content)
      }) |>
      paste(collapse = "")

    paste0(theme_header, provider_content)
  }) |>
  paste(collapse = "\n\n")

# Write comprehensive hierarchical markdown to file
theme_analysis_markdown |>
  writeLines(here("result", "qualitative", "theme_analysis.md"))

theme_markdown_en <- theme_and_code |>
  arrange(theme_en, provider, category, sub_theme_en, code_en) |>
  group_by(theme_en) |>
  group_split() |>
  map_chr(function(theme_group) {
    theme_header <- paste0("## Theme: ", first(theme_group$theme_en), "\n\n")

    provider_content <- theme_group |>
      group_by(provider) |>
      group_split() |>
      map_chr(function(provider_group) {
        provider_header <- paste0("### Provider: ", first(provider_group$provider), "\n\n")

        category_content <- provider_group |>
          group_by(category) |>
          group_split() |>
          map_chr(function(category_group) {
            category_header <- paste0("#### Category: ", first(category_group$category), "\n\n")

            sub_theme_content <- category_group |>
              group_by(sub_theme_en) |>
              group_split() |>
              map_chr(function(sub_group) {
                sub_name <- first(sub_group$sub_theme_en)
                sub_header <- paste0("- SubTheme: ", sub_name, "\n")

                codes_content <- sub_group |>
                  group_by(code_en) |>
                  group_split() |>
                  map_chr(function(code_group) {
                    code_name <- first(code_group$code_en)
                    code_line <- paste0("    - Code: ", code_name, "\n")

                    raw_text <- code_group |>
                      filter(!is.na(text_en) & nzchar(text_en)) |>
                      pull(text_en) |>
                      paste(collapse = "\n")

                    text_block <- ""
                    if (nzchar(raw_text)) {
                      text_lines <- str_split(raw_text, "\n") |> unlist()
                      indented <- paste0("        ", text_lines)
                      text_block <- paste0(indented, collapse = "\n")
                      text_block <- paste0(text_block, "\n")
                    }

                    paste0(code_line, text_block)
                  }) |>
                  paste(collapse = "")

                paste0(sub_header, codes_content)
              }) |>
              paste(collapse = "")

            paste0(category_header, sub_theme_content)
          }) |>
          paste(collapse = "\n")

        paste0(provider_header, category_content)
      }) |>
      paste(collapse = "\n")

    paste0(theme_header, provider_content)
  }) |>
  paste(collapse = "\n")


# Write English comprehensive hierarchical markdown to file
theme_markdown_en |>
  writeLines(here("result", "qualitative", "theme_analysis_en.md"))

# Create theme_analysis dataframe grouped by provider, category, theme
theme_table <- theme_and_code |>
  group_by(theme, provider, category, sub_theme) |>
  summarise(
    codes = list(unique(code)),
    codes_en = list(unique(code_en)),
    refs = list(unique(unlist(refs))),
    .groups = "drop"
  )

# Save theme_analysis as CSV
theme_table |>
  mutate(
    codes = map_chr(codes, ~ paste(.x, collapse = ", ")),
    refs = map_chr(refs, ~ paste(.x, collapse = ", "))
  ) |>
  readr::write_excel_csv(here("data", "qualitative", "theme_table.csv"), na = "")

# Create English version of theme_analysis without theme and codes columns
theme_table_en <- theme_and_code |>
  select(theme_en, provider, category, sub_theme_en, code_en, refs) |>
  mutate(
    codes = map_chr(code_en, ~ paste(.x, collapse = ", ")),
    theme = theme_en,
    sub_theme = sub_theme_en,
    refs = map_chr(refs, ~ paste(.x, collapse = ", "))
  ) |>
  select(theme, provider, category, sub_theme, codes, refs)

theme_table_en |>
  readr::write_excel_csv(here("data", "qualitative", "theme_table_en.csv"), na = "")

theme_table_en_simple <- theme_table_en |>
  select(theme, provider, sub_theme) |>
  distinct(sub_theme, .keep_all = TRUE) |>
  arrange(theme, provider, sub_theme)

theme_table_en_simple |>
  readr::write_excel_csv(here("result", "qualitative", "theme_table_en_simple.csv"), na = "")
