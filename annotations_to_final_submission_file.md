## How to turn your annotation and audio files into files for submission to the IEN wildlife acoustics dataset project

Through this document, I will guide you through the steps to extract the data from the RAVEN Pro/Lite annotation files as well as the audio files which were annotated into a the finished xlsx file format required for submission for the IEN wildlife acoustics dataset project. This will also make use of personal eBird and/or iNaturalist data to provide the closest coordinates for the recording location of a given audio file. This will require downloading them from the respective websites.

## Download your iNaturalist data

1.  Login to your iNaturalist account at inaturalist.org.

2.  Go to the "Observations" or "Your Observations" section.

3.  Click the "Filters" button located in the top right corner of the screen.

4.  On the gray popup screen, click on "Download". 

5.  On the "Export Observations" screen, you can retain the default options, except the following: i) Under the "Create a Query", you will see a field called "User". Here, add your iNaturalist user name (you can know this by clicking on 'Profile' on the top right drop-down menu, and the name on the top left on the landing page is the user name/id) ii) Under the "Choose columns" where you will see a section called "Geo (All \| None)". This is the geographic information. Click on the "All" in the brackets for this section.

6.  Scroll to the bottom of the page and click the "Create Export" button. You will receive a message confirming that the export is being processed. This may take some time depending on the size of your data set.

7.  Once the export is complete, you will receive a green message indicating it's ready. Click the "Download" link to get your data file.

8.  Download/Copy the data to a specific folder, and extract the zip file. The zip file name would something like observations-605942.csv.zip, and the unzipped file of interest will be "observations-605942.csv" in this case (within a folder of the same name).

## Download your eBird data

1.  Login to your eBird account at ebird.org

2.  Go to the the "My Ebird" section.

3.  Click on the "Download My Data" on bottom of the left pane (just above "Sign out").

4.  Click on "submit" on the resulting page.

5.  Go check your associated email ID inbox, and they would have sent an download link there.

6.  Click on the url in that email to download the data.

7.  Download/Copy the data to a specific folder (same place where the iNaturalist data was downloaded to, if downloaded), and extract the zip file. The zip file will be named something like "ebird_1755536365090.zip", and the unzipped file of interest will be "MyEBirdData.csv" in the folder named "ebird_1755536365090".

## Download the annotation template

From the Github project <https://github.com/paulvpop/ecoacoustics>, download the file titled "annotation_template.xlsx" which is the cleaned version of the template available from the Acoustic Data Upload Form available [here](https://docs.google.com/forms/d/e/1FAIpQLSctSuX61-9fdV46nuTm_tP4dzOoLL4CoIN2lg7LMI9pHVJb_w/viewform). Keep it in the same folder as the above files.

## RAVEN annotation data

Copy all the annotations files (which will likely be in the folder "Selections" under "RavenPro1.x" where x is the version number. It should be the same in Raven Lite too) to a folder titled "annotations" in the same folder where the iNaturalist and/or eBird data and the annotation template is kept.

The annotation files provided by RAVEN will be of the following general format (where "Scientific Name" is the column you add).

| Selection | View | Channel | Begin Time (s) | End Time (s) | Low Freq (Hz) | High Freq (Hz) | Scientific Name |
|---------|---------|---------|---------|---------|---------|---------|---------|
| 1 | Spectrogram 1 | 1 | 0.693978986 | 1.786353317 | 1863.4 | 4831.0 | Dicrurus macrocercus |
| 2 | Spectrogram 1 | 1 | 3.762165563 | 5.307016156 | 2173.9 | 5245.1 | Spilopelia senegalensis |

## Audio files

Copy all the audio files that were used for annotation to the same folder as above and name it 'audio'

## Data extraction

Now that all the files are in the same place, we can start.

Open RStudio (first install R and RStudio it if you haven't, using the help [from here](https://posit.co/download/rstudio-desktop/#))

Step 1. Set the working directory.

This will be the folder containing all the above files. For this, Press Ctrl+Shift+H to interactively choose the wanted directory OR (for Windows) copy (but don't paste) the directory path, which will look like this: "D:/Name/Bioacoustics" and run the next two lines of code

``` r
FolderPath <- normalizePath(readClipboard(), "/")
setwd(FolderPath)
```

In Linux, one can just copy-paste the folderpath (can be found if the folder is opened in the terminal) directly. Don't forget to change the name of the path in quotes with your own:

``` r
setwd("~/Wildlife/Bioacoustics/For submission")
```

To verify the location of the current working directory (optional)

```         
getwd() 
```

See the files in the folder (optional)

```         
list.files()
```

Step 2. Load most of the files into the RStudio environment.

To do this, first install the package readxl if you don't have it already, and then load this library.

``` r
install.packages("readxl")
library(readxl)
```

Then we will load the relevant files one by one. The str() functions shows all the columns within those files.

```         
Meta <- read_excel("annotation_template.xlsx",
                       sheet = "Meta",
                       col_types = "text")
                       
Annotations <- read_excel("annotation_template.xlsx",
                       sheet = "Annotations",
                       col_types = "text")

Authors <- read_excel("annotation_template.xlsx",
                       sheet = "Authors",
                       col_types = "text")

str(Meta)
str(Annotations)
str(Authors)

inat <- read.csv("observations-605942.csv/observations-605942.csv")
str(inat)

ebird <- read.csv("ebird_1755536365090/MyEBirdData.csv")
str(ebird)
```

We are not loading the tab "Guide" as it is just there for help, and not for data input.

Of interest in the iNat data is the column "observed_on_string" which gives the date and time as a string in IST format (which is important since the dataset is India-focused). Check the first 10 observations in the column to see how it looks like:

```         
head(inat$observed_on_string, 10)
```

It will look like the following:

```         
 [1] "2017/07/08 "             "2017/07/08 "             "2016/09/22 "             "2017/10/30"             
 [5] "2017-11-01"              "2017-11-01"              "2017-07-08"              "2017-10-30"             
 [9] "2017/05/27 10:10 PM IST" "2018/03/15 9:48 AM IST" 
 
```

Check the last 10 observations:

```         
tail(inat$observed_on_string, 10)
```

```         
[1] "2025-07-31 11:36:37" "2025-07-31 12:52:33" "2025-07-31 15:14:03" "2025-07-31 15:24:00" "2025-07-31 15:25:37" [6] "2025-08-03 09:31:38" "2025-08-15 17:32:33" "2025-08-15 17:45:41" "2025-08-15 18:11:41" "2025-08-16 16:44:58"
```

We see that iNaturalist date-time is not standardised. So, it needs to be done in a later step.

Of interest in the eBird data are the columns "Date" and "Time" which gives the date and time as strings in IST format. Check the first 10 observations to see how it looks like:

```         

head(ebird$Date, 10)
head(ebird$Time, 10)
```

```         

[1] "2024-01-15" "2024-01-15" "2024-01-15" "2025-02-16" "2024-12-29" "2025-04-20" "2024-07-13" "2024-10-01" [9] "2024-08-11" "2024-07-13"
```

```         
[1] "08:00 AM" "07:12 AM" "06:40 AM" "11:50 AM" "06:00 PM" "05:41 AM" "08:11 AM" "07:07 AM" "09:07 AM" "08:30 AM"
```

We know that eBird Date and Time are standardised as it is outputted as such (in IST in case of this dataset).

Now we need to extract the metadata of the annotation files to get their file

Step 3. Extract metadata from the annotation files

Install the exiftoolr package:

```         
if (!require("exiftoolr")) install.packages("exiftoolr") 
library(exiftoolr)
```

Ignore "Warning message: package ‘exiftoolr’ was built under R version 4.3.3" (if you see it)

Install exiftool if already not present:

```         
install_exiftool()
```

Change the working directory to folder containing ONLY annotations files.

In Linux:

```         
setwd(~/Wildlife/Bioacoustics/For submission/annotations") 
```

In Windows (copy the file path and then):

```         
FolderPath <- normalizePath(readClipboard(), "/")
setwd(FolderPath)
```

Get the names (and extensions) of all the files present in the directory:

```         
file_names <- list.files()
```

Extract all the meta-data:

```         
data <- exif_read(file_names)
```

View 10 rows of data from the created table and check its class (optional):

```         
head(data, 10) 

1  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt           13.34
2                                                        2025-07-31 13_09.annotations.txt           13.34
3                                                        2025-08-03 08_42.annotations.txt           13.34
4                                                        2025-08-03 08_45.annotations.txt           13.34
5                                                        2025-08-03 08_53.annotations.txt           13.34
6                             2025-08-03 09_29 Puff-throated Babbler song.annotations.txt           13.34
7                                                        2025-08-03 09_57.annotations.txt           13.34
8                                                        2025-08-03 10_06.annotations.txt           13.34
9                                                        2025-08-10 12_14.annotations.txt           13.34
10                                                       2025-08-10 12_18.annotations.txt           13.34
                                                                                 FileName Directory FileSize
1  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt         .      777
2                                                        2025-07-31 13_09.annotations.txt         .     2366
3                                                        2025-08-03 08_42.annotations.txt         .      567
4                                                        2025-08-03 08_45.annotations.txt         .      243
5                                                        2025-08-03 08_53.annotations.txt         .     1593
6                             2025-08-03 09_29 Puff-throated Babbler song.annotations.txt         .      701
7                                                        2025-08-03 09_57.annotations.txt         .      328
8                                                        2025-08-03 10_06.annotations.txt         .      745
9                                                        2025-08-10 12_14.annotations.txt         .     1879
10                                                       2025-08-10 12_18.annotations.txt         .     1695
              FileModifyDate            FileAccessDate       FileInodeChangeDate FilePermissions FileType
1  2025:08:16 16:25:01+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
2  2025:08:16 16:08:14+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
3  2025:08:16 15:34:40+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
4  2025:08:16 13:40:59+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
5  2025:08:16 15:17:30+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
6  2025:08:15 15:15:47+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
7  2025:08:15 00:16:48+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
8  2025:08:15 00:06:55+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
9  2025:08:15 00:00:07+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
10 2025:08:14 21:35:57+05:30 2025:08:23 14:30:16+05:30 2025:08:18 23:06:26+05:30          100664      TXT
   FileTypeExtension   MIMEType MIMEEncoding Newlines LineCount WordCount
1                TXT text/plain     us-ascii       \n        10       107
2                TXT text/plain     us-ascii       \n        30       307
3                TXT text/plain     us-ascii       \n         7        77
4                TXT text/plain     us-ascii       \n         3        37
5                TXT text/plain     us-ascii       \n        21       218
6                TXT text/plain     us-ascii       \n         9        97
7                TXT text/plain     us-ascii       \n         4        47
8                TXT text/plain     us-ascii       \n        10       107
9                TXT text/plain     us-ascii       \n        25       257
10               TXT text/plain     us-ascii       \n        22       227
```

```         
class(data)

[1] "exiftoolr"  "data.frame"
```

The LineCount column is important as it tells how many annotations (bounding boxes) you have made. Check the total number of annotations you have made (Subtracting the rows containing the column headers using no. of rows in 'data' as proxy):

```         
sum(data$LineCount) - nrow(data)

[1] 250
```

So, there are 250 annotations in my data.

Step 4. Combine all the annotation files in the folder using the following steps:

a.  Read all files into a list of data frames:

```         
data_list <- lapply(file_names, function(file) {
  df <- read.table(file, sep = "\t", header = TRUE) # For tab-limited seperator (tsv)
  df$filename <- basename(file) #Add filename column
  return(df)
})
```

b.  Combine all data frames into one and check the first 15 entries

```         
combined_annotations <- do.call(rbind, data_list)
head(combined_annotations,15)

   Selection          View Channel Begin.Time..s. End.Time..s. Low.Freq..Hz. High.Freq..Hz.    Scientific.Name
1          1 Spectrogram 1       1       2.191570     7.464620         805.2         1366.4 Psilopogon viridis
2          3 Spectrogram 1       1       8.288119    17.718510         780.8         1293.2 Psilopogon viridis
3          4 Spectrogram 1       1      21.686255    23.944236         780.8         1293.2 Psilopogon viridis
4          5 Spectrogram 1       1      24.634912    25.073226         707.6         1342.0 Psilopogon viridis
5          6 Spectrogram 1       1      25.843596    26.149088         780.8         1390.8 Psilopogon viridis
6          7 Spectrogram 1       1      27.025716    27.384336         829.6         1415.2 Psilopogon viridis
7          8 Spectrogram 1       1      25.139637    28.260964        2757.2         6807.6    Prinia socialis
8          9 Spectrogram 1       1       5.339461     9.828859        2464.4        11687.7 Dumetia hyperythra
9         10 Spectrogram 1       1      11.316470    12.139969        2464.4         9711.3 Dumetia hyperythra
10         1 Spectrogram 1       1       0.708047     1.267031        3623.2        20842.3 Cyornis tickelliae
11         2 Spectrogram 1       1       2.111719     2.720391        3485.2        21152.8 Cyornis tickelliae
12         3 Spectrogram 1       1       3.813516     5.801016        2829.6        21773.9 Cyornis tickelliae
13         4 Spectrogram 1       1       7.005938     9.502736        3174.6        21808.5 Cyornis tickelliae
14         5 Spectrogram 1       1      10.459220    12.334923        2657.0        21187.3 Cyornis tickelliae
15         6 Spectrogram 1       1      13.949767    14.757189        3554.2        21428.9 Cyornis tickelliae
                                                                                 filename
1  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt
2  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt
3  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt
4  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt
5  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt
6  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt
7  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt
8  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt
9  2025-07-31 13_01 Dumetia hyperythra per per collecting leaves for nest.annotations.txt
10                                                       2025-07-31 13_09.annotations.txt
11                                                       2025-07-31 13_09.annotations.txt
12                                                       2025-07-31 13_09.annotations.txt
13                                                       2025-07-31 13_09.annotations.txt
14                                                       2025-07-31 13_09.annotations.txt
15                                                       2025-07-31 13_09.annotations.txt
```

Step 5. Restructure the data in the form as 'Annotations' format

Load the dplyr library:

```         
library(dplyr)
```

Rename the column names in the 'combined_annotations' object, add the missing columns (from the 'Annotations' object), and rearrange the columns to the match the structure of 'Annotations':

```         
Annotations <- combined_annotations %>%   
rename(`Media File Name/Media URL`= filename,
       `Begin Time (s)`= Begin.Time..s.,
       `End Time (s)`= End.Time..s.,
       `Low Freq (Hz)`= Low.Freq..Hz.,
       `High Freq (Hz)`= High.Freq..Hz.,
       `Scientific Name`= Scientific.Name) %>%   
mutate(`Organism Seen?`= NA_character_,     
        Notes = NA_character_,
        `Behaviour`= NA_character_) %>%   
select(`Media File Name/Media URL`,
       `Begin Time (s)`,
       `End Time (s)`,
       `Low Freq (Hz)`,
       `High Freq (Hz)`,
       `Scientific Name`,
       `Organism Seen?`,
       Notes,
       `Behaviour`)


#View the result

head(Annotations, 15)
```

From this data, you can check how many species or classes there are in all of your annotations combined:

```         
unique(Annotations$`Scientific Name`)

 [1] "Psilopogon viridis"            "Prinia socialis"               "Dumetia hyperythra"           
 [4] "Cyornis tickelliae"            "Orthotomus sutorius"           "Dicrurus macrocercus"         
 [7] "Spilopelia senegalensis"       "Prinia hodgsonii"              "Saxicola caprata"             
[10] "Homo sapiens"                  "Recorder movement noise"       "Pellorneum ruficeps"          
[13] "Corvus splendens"              "Cacomantis passerinus"         "Pycnonotus luteolus"          
[16] "Vehicular noise"               "Parus cinereus"                "Oriolus xanthornus"           
[19] "Cinnyris lotenius"             "Canis lupus subsp. familiaris" "Accipiter badius"             
[22] "Dicaeum erythrorhynchos"       "Centropus sinensis"            "Turdoides affinis"            
[25] "Acridotheres tristis"          "Funambulus"                    "Glaucidium radiatum" 

length(unique(Annotations$`Scientific Name`))

[1] 27
```

So, there are 27 classes and 25 species (Vehicular noise and Recorder movement noise excluded) in all my annotations put together

Step 6. Extract metadata from the audio files

Change the working directory to folder containing ONLY audio files.

In Linux:

```         
setwd(~/Wildlife/Bioacoustics/For submission/audio") 
```

In Windows (copy the file path and then):

```         
FolderPath <- normalizePath(readClipboard(), "/")
setwd(FolderPath)
```

Get the names (and extensions) of all the files present in the directory:

```         
file_names <- list.files()
```

Extract all the meta-data:

```         
data_audio <- exif_read(file_names)
```

View 15 rows of data from the created table and check its class (optional):

```         
head(data_audio, 14) 
```

Step 7. Find the closest date-time and corresponding coordinates for a given recording

Load the necessary libraries (other than dplyr which has already been loaded):

```         
library(lubridate)
library(purrr)
```

a.  Standardize date-time formats across all datasets

First, convert data_audio's 'FileModifyDate' column to proper datetime, after removing the timezone offset (+05:30)

```         
data_audio$FileModifyDate_clean <- ymd_hms(sub("\\+05:30$", "", data_audio$FileModifyDate))
```

b.  Extract date and time components for data_audio

```         
data_audio$audio_date <- as.Date(data_audio$FileModifyDate_clean)
data_audio$audio_time <- format(data_audio$FileModifyDate_clean, "%H:%M:%S")
```

c.  Standardize iNaturalist dates, by handling different date formats in observed_on_string

First trim the whitespace in inat 'observed_on_string' column:

```         
inat <- inat %>%
  mutate(observed_on_string = trimws(observed_on_string))
```

```         
inat_clean <- inat %>%
  mutate(
    obs_date_time = case_when(
    # Pattern 1: Dates like "2017/05/27 10:10 PM IST" or "2017/05/27 10:10 PM"
      grepl("^\\d{4}/\\d{2}/\\d{2} \\d{1,2}:\\d{2} [AP]M", observed_on_string) ~ 
        suppressWarnings(parse_date_time(observed_on_string, orders = c("Y/m/d I:M p", "Y/m/d I:M"))),
    # Pattern 2: ISO 8601 format with seconds. E.g. "2017-10-30 12:34:56"
      grepl("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$", observed_on_string) ~ 
        suppressWarnings(ymd_hms(observed_on_string)),
    # Pattern 3: Simple date with slashes. E.g. "2017/07/08"
      grepl("^\\d{4}/\\d{2}/\\d{2}$", observed_on_string) ~ 
        suppressWarnings(ymd(observed_on_string)),
    # Pattern 4: Simple date with hyphens. E.g. "2017-07-08"  
      grepl("^\\d{4}-\\d{2}-\\d{2}$", observed_on_string) ~ 
        suppressWarnings(ymd(observed_on_string)),
    # Pattern 5: Simple date with hyphens and literal time-of-day (Noon). 
    # E.g. 2017-07-08 Noon
    grepl("^\\d{4}/\\d{2}/\\d{2} Noon$", observed_on_string) ~ 
        suppressWarnings(ymd_hms(paste0(sub(" Noon$", "", observed_on_string), " 12:00:00"))),
    # No pattern: if no patterns match, it is set as NA (but this ideally not
    # happen):  
      TRUE ~ NA_POSIXct_
    )
  )
```

In the above code chunk, the explanations for the patterns are:

Pattern 1: The explanation for the above code is that grepl function is used to to check if a string matches pattern: YYYY/MM/DD HH:MM AM/PM. The components of the string: \^ = start of string, \\d{4} = check if its exactly 4 digits (year), / = literal slash, \\d{2} = check if its exactly 2 digits (for month, day, minute), \\d{1,2} = check if its either 1 or 2 digits (hour), : = literal colon, [AP]M = check if its either "AM" or "PM" parse_date_time function tries to parse using format "Year/month/day Hour:Minute AM/PM" If that fails, it tries "Year/month/day Hour:Minute" (without AM/PM)

Pattern 2: The grepl function checks if string matches pattern: YYYY-MM-DD HH:MM:SS Code explanation similar to Pattern 1, but in this case instead of literal slashes, we check matches for hyphens, and there is an addition of second information, and there are no AM/PM classification as it is a 24 hour format. ymd_hms converts the string to datetime object

Pattern 3: The grepl functions check if string matches pattern: YYYY/MM/DD. ymd converts the string to date object (time set to 00:00:00)

Pattern 4: The grepl function checks if the string matches pattern: YYYY-MM-DD

Pattern 5: The grepl function checks if the string matches pattern: YYYY-MM-DD Noon. Then deletes 'Noon'.

d.  Standardize eBird dates

```         
ebird_clean <- ebird %>%
  mutate(
    # Convert Date to proper Date class
    ebird_date = as.Date(Date),
    
    # Convert Time from AM/PM to 24-hour format with seconds
    ebird_time = format(strptime(Time, "%I:%M %p"), "%H:%M:%S")
  )
```

e.  Create a function to find closest observation for each audio file

```         
find_closest_observation <- function(audio_date, audio_time, dataset, date_col, time_col, id_col) {
  # Filter dataset for matching date
  same_date_obs <- dataset[dataset[[date_col]] == audio_date, ]
  
  if (nrow(same_date_obs) == 0) {
    return(list(id = NA, time_diff = NA))
  }
  
  # Convert times to seconds for comparison
  audio_seconds <- period_to_seconds(hms(audio_time))
  obs_seconds <- period_to_seconds(hms(same_date_obs[[time_col]]))
  
  # Calculate time differences
  time_diffs <- abs(audio_seconds - obs_seconds)
  min_diff_idx <- which.min(time_diffs)
  min_diff <- time_diffs[min_diff_idx]
  
  return(list(
    id = same_date_obs[[id_col]][min_diff_idx],
    time_diff = min_diff,
    source = deparse(substitute(dataset))
  ))
}
```

f.  Process each audio file, add the details to a newly created 'Meta' dataframe

```         
Meta <- data_audio %>%
  mutate(
    # Extract basic info
    `Media File Name/Media URL` = FileName,
    `Recording Date` = paste(
      format(audio_date, "%d"),
      month.abb[as.integer(format(audio_date, "%m"))],
      format(audio_date, "%Y"),
      sep = "-"
                            ),
    `Recording Time` = format(FileModifyDate_clean, "%H:%M:%S"),
    `Annotation File Attached` = "No", #Since the data from annotation files have already been extracted
    `Recording Duration (s)` = Duration,
    `Sample Rate (Hz)` = SampleRate,
    `No. of Channels` = NumChannels,
    `File Size (bytes)` = FileSize,
    `File Type` = FileType,
    `Encoding` = Encoding,
    `Bits per Sample` = BitsPerSample,
    
    # Initialize empty columns
    `Location Latitude` = NA_character_,
    `Location Longitude` = NA_character_,
    `Authors` = NA_character_,
    `Hide Exact Location` = NA_character_,
    `Recording Type` = NA_character_,
    `Notes` = NA_character_,
    `Habitat` = NA_character_
  ) %>%
  
  #Order the columns in the following manner to be consistent with the template:
  select(
    `Media File Name/Media URL`, `Location Latitude`, `Location Longitude`,
    `Recording Date`, `Authors`, `Annotation File Attached`, `Recording Time`,
    `Hide Exact Location`, `Recording Type`, `Notes`, `Habitat`, `Recording Duration (s)`,
    `Sample Rate (Hz)`,`No. of Channels`,`File Size (bytes)`,`File Type`, `Encoding`, 
    `Bits per Sample`)
```

g\. Find closest observations and populate coordinates

```         
#Use a for-loop for finding the closest observation for each row of the data_audio object
for (i in 1:nrow(data_audio)) {
  audio_row <- data_audio[i, ]
  
  # Check iNaturalist first
  inat_match <- find_closest_observation(
    audio_row$audio_date, audio_row$audio_time,
    inat_clean, "inat_date", "inat_time", "id"
  )
  
  # Check eBird if no iNaturalist record match or if time difference is too large
  ebird_match <- find_closest_observation(
    audio_row$audio_date, audio_row$audio_time,
    ebird_clean, "ebird_date", "ebird_time", "Submission.ID"
  )
  
  # Choose the best match (smallest time difference)
  if (!is.na(inat_match$time_diff) && 
      (is.na(ebird_match$time_diff) || inat_match$time_diff <= ebird_match$time_diff)) {
    # Use iNaturalist data
    matched_obs <- inat_clean[inat_clean$id == inat_match$id, ]
    Meta[i, "Location Latitude"] <- as.character(matched_obs$latitude)
    Meta[i, "Location Longitude"] <- as.character(matched_obs$longitude)
    Meta[i, "Data Source"] <- "iNaturalist"
    
  } else if (!is.na(ebird_match$time_diff)) {
    # Use eBird data
    matched_obs <- ebird_clean[ebird_clean$Submission.ID == ebird_match$id, ]
    # Take the first lat and lon since eBird data will have same submission id for
    # different species in the same checklist:
    Meta[i, "Location Latitude"] <- as.character(matched_obs$Latitude[1])
    Meta[i, "Location Longitude"] <- as.character(matched_obs$Longitude[1])
    Meta[i, "Data Source"] <- "eBird"
  }
  # If no match, coordinates remain NA
}
```

Note that the above for-loop will also add a column titled 'Data Source' which will either say eBird or iNaturalist. It means that the latitude and longitude data is coming from one of these sources. This is for you to cross-reference some coordinates or check if there are any errors. You should ideally delete this column before submission. You can use the following for this step:

```         
Meta$`Data Source` <- NULL
```

Similarly. you can delete other columns like 'Habitat' that you don't have the data or don't want to fill up.

We can get the total file size of all the audio files combined (in GiB - Gibibytes):

```         
sum(Meta$`File Size (bytes)`)/1073741824
[1] 0.102001
```

In GB (Gigabytes)

```         
sum(Meta$`File Size (bytes)`)/1000000000
[1] 0.1095227
```

That's around 109.5 MB

You can also check the total duration of recordings (in minutes):

```
sum(Meta$`Recording Duration (s)`)/60

[1] 10.34783
```

That means I have annotated over 10 minutes of audio recordings.

The only mandatory column not filled is the "Authors" column as different recordings may have multiple authors. You can fill it up (with commas seperating the authors if multi-author) once you download the file at the end of this walkthrough.

## Data input

Now that we have the two main sheets, which have data extracted from multiple sources, we can fill up the remaining sheet, i.e. "Authors" sheet. Replace the content in the double quotes with your data in the following code chunk:

```         
Authors <- data.frame(
  Author = c("Paul Pop", "Verditer Flycatcher"),
  `Email ID` = c("paulpop.bioacoustics@gmail.com", "verdi@himalaya.com"),
  Affiliations = c("SaCoLib, ATREE", "Mountains"),
  check.names = FALSE  # This preserves the column names with spaces
)
```

## Data combining and download

Now that we have all the files ready, combine all the files 'Meta', 'Annotations', and 'Authors':

Install the openxlsx package if not already installed, and load it:

```         
install.packages("openxlsx")
library(openxlsx)   
```

Change the working directory again back to the main folder ("\~/Wildlife/Bioacoustics/For submission") in this example. Then save the file there.

Create the list of data frames with sheet names:

```         
data_frames <- list("Meta" = Meta, "Annotations" = Annotations, "Authors" = Authors)
```

Download as xlsx file:

```         
write.xlsx(data_frames, file = "Paul_Pop_batch1_meta_annotation_typeA.xlsx")
```

## Manual data entry

VERY VERY IMPORTANT: YOUR WORK IS NOT DONE YET. The following needs to be done:

1. In the 'Meta' tab of the downloaded xlsx file, you have to fill up the mandatory
'Authors' column.

2. You should copy-paste every unique coordinates from 'Location Latitude' and 
'Latitude Longitude' column, and paste it in Google Maps, Google Earth or other map services
to check if the coordinates are the closest to the recording location. If not, it should be
corrected. Note that the autopopulated coordinates can lie VERY far away from the 
recording location if you have travelled a long distance after making that recording on the
same date.

If you have been recording in or around your home or other private areas, and don't want to reveal
the exact coordinates, you can just put the coordinates a little further away 500-1 km ideally,
and then create a column titled 'Coordinate Precision' and put 500 or 1000 (in metres) for
such coordinates. This is preferable over completely hiding the coordinates from public
output, which is also another option we provide.

3. Try to fill up non-mandatory columns like 'Organism Seen' for enriching the dataset
with very useful information.

## Create the zip file

We need to combine the folder containing the audio and the xlsx file created, and then zip it.

First list the files to be zipped (change the name from "Paul_Pop" to the one you used in the 'Data combining and download' step)

```         
audio_files <- list.files("audio", full.names = TRUE)
excel_file <- "Paul_Pop_batch1_meta_annotation_typeA.xlsx"
```

Check if the file exists in the working directory (if not, it will give a warning message)

```         
if(!file.exists(excel_file)) {
  stop("Excel file not found: ", excel_file)
}
```

Create a directory (if it has not been created already). NOTE: Change the folder name to match with the naming of the annotation xlsx in your case.

```         
if(!dir.exists("Paul_Pop_files_for_submission_batch_1")) {
  dir.create("Paul_Pop_files_for_submission_batch_1")
}
```

Copy the filepath for this folder. NOTE: Change the folder name to match with the naming of the annotation xlsx.

```         
path <- file.path("Paul_Pop_files_for_submission_batch_1")
```

Copy files to this directory

```         
file.copy(audio_files, path)
file.copy(excel_file, path)
```

Create zip using relative paths

```         
zip("zipped_files.zip", files = path)
```
You now have a zip file containing the folder to be submitted. Submit the zip file using [this Acoustic Data Upload Form](https://docs.google.com/forms/d/e/1FAIpQLSctSuX61-9fdV46nuTm_tP4dzOoLL4CoIN2lg7LMI9pHVJb_w/viewform).
