# QScript - Stock Research & Analysis

QScript is a comprehensive stock research and note-taking application designed for investors who want to combine real-time market data with advanced AI-powered insights.

## Features

- **Real-time Market Data**: Track live stock quotes, price changes, and historical charts powered by the Financial Modeling Prep (FMP) API.
- **Personalized Watchlist**: Manage a custom list of stocks you're interested in, with instant price updates.
- **Multi-Tab Stock Details**: 
  - **Info**: Comprehensive overview including market cap, volume, day high/low, and company profile.
  - **News**: Stay updated with the latest company-specific news fetched from the Finnhub API.
  - **Notes**: Organize your research with dedicated notes for each ticker.
- **AI-Powered Sentiment Analysis**: 
  - Integrated with a fine-tuned **FinBERT** model for financial sentiment prediction (Bearish/Neutral/Bullish).
  - **Gemini 2.5** integration for deep reasoning and context-aware interpretation of news headlines and summaries.
- **Research Library**: Save AI-generated insights directly to your notes, including sentiment labels, detailed reasoning, and reference links to original news articles.

## Tech Stack

- **Frontend**: Flutter & Dart
- **State Management**: Provider
- **Local Storage**: SQFlite (for notes) & Shared Preferences (for watchlist)
- **External APIs**: 
  - Financial Modeling Prep (Market Data)
  - Finnhub (News Data)
  - Custom AI Service (FinBERT & Gemini)

## Project Structure

```text
lib/
├── models/          # Data models (StockQuote, Note, etc.)
├── providers/       # State management (Watchlist, Notes)
├── screens/         # UI Screens (Watchlist, Details, Editor)
├── services/        # API and Database services
└── main.dart        # App entry point
assets/              # Images and static assets
test/                # Unit and widget tests
```

---
*Developed as a term project for stock market enthusiasts.*
