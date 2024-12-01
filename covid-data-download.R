# Load required packages
if (!require(httr)) install.packages("httr")
if (!require(jsonlite)) install.packages("jsonlite")
library(httr)
library(jsonlite)

# Function to download COVID-19 daily reports from JHU CSSE GitHub repository
download_covid_reports <- function(base_path = "data/covid", start_date = "2020-01-22") {
  # Create directory if it doesn't exist
  if (!dir.exists(base_path)) {
    dir.create(base_path, recursive = TRUE)
  }
  
  # GitHub API endpoint for the repository contents
  api_url <- "https://api.github.com/repos/CSSEGISandData/COVID-19/contents/csse_covid_19_data/csse_covid_19_daily_reports"
  
  # Get repository contents with detailed error handling
  message("Fetching repository contents...")
  response <- GET(api_url)
  if (status_code(response) != 200) {
    stop(sprintf("Failed to access GitHub API. Status code: %d\nResponse: %s", 
                 status_code(response), 
                 rawToChar(response$content)))
  }
  
  # Parse JSON response
  files <- fromJSON(rawToChar(response$content))
  
  # Filter for CSV files
  csv_files <- files[grep("\\.csv$", files$name), ]
  message(sprintf("Found %d CSV files in repository", nrow(csv_files)))
  
  # Download each CSV file
  successful_downloads <- 0
  failed_downloads <- 0
  
  for (i in 1:nrow(csv_files)) {
    file_name <- csv_files$name[i]
    download_url <- csv_files$download_url[i]
    
    # Create local file path
    local_path <- file.path(base_path, file_name)
    
    # Download file
    tryCatch({
      message(sprintf("[%d/%d] Downloading %s...", i, nrow(csv_files), file_name))
      download.file(download_url, local_path, mode = "wb", quiet = TRUE)
      successful_downloads <- successful_downloads + 1
      Sys.sleep(0.5)  # Reduced delay to 0.5 seconds
    }, error = function(e) {
      warning(sprintf("Failed to download %s: %s", file_name, e$message))
      failed_downloads <- failed_downloads + 1
    })
  }
  
  # Print summary
  message("\nDownload Summary:")
  message(sprintf("Total files found: %d", nrow(csv_files)))
  message(sprintf("Successfully downloaded: %d", successful_downloads))
  message(sprintf("Failed downloads: %d", failed_downloads))
}

# Usage example
# Set your desired download path
download_path <- "covid_data"

# Run the download function
download_covid_reports(download_path)