# Recentpedia CLI Tool
## Introduction
Recentpedia is a command line tool designed to fetch newly created Wikipedia articles that are significant. The tool prioritizes substantial content by excluding brief articles, sports-related topics (sorry but there is just a lot of garbage data), and entries about individuals born before 1900.

The result is an interesting assortment of obscure and eclectic articles.
## Example Output
```bash
(base) puter$ make run
Running the script...
ruby recentpedia.rb
Fetching recently changed articles from Wikipedia...
500 articles fetched.
Classifying article titles using OpenAI...
Articles:
1. The Viking of Van Diemen's Land - https://en.wikipedia.org/wiki/The_Viking_of_Van_Diemen%27s_Land
2. Legacy of the Qing dynasty - https://en.wikipedia.org/wiki/Legacy_of_the_Qing_dynasty
3. 62nd Infantry Regiment (PA) - https://en.wikipedia.org/wiki/62nd_Infantry_Regiment_%28PA%29
4. List of listings of US military actions - https://en.wikipedia.org/wiki/List_of_listings_of_US_military_actions
5. 2024 Tasmanian government formation - https://en.wikipedia.org/wiki/2024_Tasmanian_government_formation
```
## Setup Instructions
### Prerequisites
- Ensure you have Ruby installed on your computer.
- You need an OpenAI API key to classify Wikipedia titles using GPT-4.
### Installation
1. Clone the repository to your local machine.
2. Navigate to the cloned directory.
3. Add your OpenAI API key to the `.env` file. Format: `OPENAI_API_KEY=your-key-here`.
4. Install the required dependencies:
```bash
make install
```
### Running the Tool
Execute the following command to start fetching and classifying newly created Wikipedia articles:
```bash
make run
```
