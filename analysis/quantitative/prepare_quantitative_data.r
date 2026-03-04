# Load the data, standardize the format,
# and exclude data that is not subject to analysis to protect privacy.

# Load necessary packages
if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman", quietly = TRUE)
}
pacman::p_load(
  tidyr,
  dplyr,
  lubridate,
  gt,
  here,
  stringr,
  rio,
  svglite,
  ggplot2,
  ordinal,
  purrr,
  broom
)

conversion_table <- rio::import(here("data", "quantitative", "raw_conversion_table.csv"))

# Read the CSV file
data <- rio::import(here("data", "quantitative", "raw_data.csv")) |>
  filter(
    !assessor %in% c(1, 2, 3), # exclude pre-testers
    !record_id %in% c(66, 106, 156) # Remove excluded data
  ) |>
  mutate(
    # Convert the time column to datetime format
    time = lubridate::ymd_hms(time, tz = "Asia/Tokyo", quiet = TRUE),
    # Extract department from source_record column (only up to line break)
    department = str_match(source_record, "^.*実習先:\\s*([^\\s\\n]*)")[, 2],
    source_record = str_replace(source_record, "^[^\\n]*\\n", ""),
    log_letter_count = nchar(source_record),
    log_date_count = str_count(source_record, "\\d{4}年\\d{1,2}月\\d{1,2}日"),
  ) |>
  # Convert department names from Japanese to English using conversion table
  left_join(conversion_table, by = c("department" = "japanese")) |>
  mutate(department = english) |>
  select(-english)

# Assign a unique ID to each feedback-target text entry
data <- data |>
  mutate(log_id = match(source_record, unique(source_record)))

# make tidy_data

# Transform the data to a long format
tidy_data <- data |>
  rename(
    student = source_student,
    feedback_provider = source_feedback_provider,
  ) |>
  select(-matches("comment|generated|source")) |>
  pivot_longer(
    cols = matches("_(ai|supervisor)$"),
    names_to = c("item", "person"),
    names_sep = "_",
    values_to = "value"
  )

# Transform the data to a long format
feedback_text_data <- data |>
  select(ID, matches("^source_feedback")) |>
  rename_with(~ gsub("^source_", "", .), starts_with("source_")) |>
  pivot_longer(
    cols = matches("^(feedback)_(ai|supervisor)$"),
    names_to = c("item", "person"),
    names_sep = "_",
    values_to = "value"
  ) |>
  mutate(feedback_letter_count = nchar(value))

feedback_text_data |>
  rio::export(here("data", "quantitative", "data_feedback_text.csv"))

tidy_data <- tidy_data |>
  left_join(
    feedback_text_data |> select(ID, feedback_provider,person, feedback_letter_count),
    by = c("feedback_provider", "person", "ID")
  ) |>
  filter(!is.na(feedback_letter_count), !is.na(value))


# Write to CSV
tidy_data |>
  rio::export(here("data", "quantitative", "data.csv"))
