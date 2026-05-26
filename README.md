# Weather Forecast App

Ruby on Rails application that accepts an address, extracts a US ZIP code, retrieves weather forecast data, caches the result for 30 minutes, and shows whether the response came from cache.

The implementation keeps controllers thin, isolates external API calls, and uses small service objects to keep the code simple, testable, and easy to evolve.

## Features

- Address input form
- US ZIP code extraction
- ZIP+4 normalization to 5-digit ZIP
- Forecast lookup using Open-Meteo APIs
- Current temperature
- Daily high and low temperatures
- Human-readable weather description
- 30-minute cache by ZIP code
- Cache status indicator
- RSpec test coverage

## Tech Stack

- Ruby 3.3.4
- Ruby on Rails
- Faraday
- Rails.cache
- RSpec
- WebMock

## Setup

Clone the repository:

```bash
git clone https://github.com/JoaoGabriel98/weather-forecast-assessment.git
git clone https://github.com/JoaoGabriel98/weather-forecast-assessment.git
cd weather_forecast_assessment
````

Install dependencies:

```bash
bundle install
```

Prepare the database:

```bash
bin/rails db:prepare
```

Start the server:

```bash
bin/rails server
```

Open the app at:

```text
http://localhost:3000
```

## Enable Cache in Development

Rails development cache may be disabled by default.

Run:

```bash
bin/rails dev:cache
```

Then restart the Rails server.

## Running Tests

```bash
bundle exec rspec
```

## Main Flow

```text
Submitted address
-> ZIP code extraction
-> Cache lookup by ZIP
-> Geocoding API lookup
-> Forecast API lookup
-> Cache write for 30 minutes
-> Render forecast result
```

## Architecture

The application keeps controllers thin and moves business logic into small service objects.

### ForecastsController

Handles HTTP concerns only:

* renders the address form
* receives submitted params
* calls `Weather::ForecastLookup`
* renders the forecast result or validation error

### Weather::ForecastLookup

Main application service and facade for the forecast lookup use case.

It coordinates:

* blank address validation
* ZIP extraction
* cache lookup
* geocoding
* forecast retrieval
* cache write
* standardized success/failure response

The controller only needs to call:

```ruby
Weather::ForecastLookup.call(address: address)
```

### AddressZipExtractor

Extracts a US ZIP code from free-form address text.

Supported formats:

```text
90210
20500-0003
```

ZIP+4 values are normalized to the base 5-digit ZIP because cache entries are grouped by ZIP code.

### Weather::GeocodingClient

Converts a ZIP code into latitude and longitude using the Open-Meteo Geocoding API.

This is separated from forecast retrieval because geocoding and weather lookup are different external API concerns.

### Weather::ForecastClient

Calls the Open-Meteo Forecast API using latitude and longitude.

It converts raw API JSON into a normalized `WeatherForecast` object, so the rest of the application does not depend on the external API response shape.

### WeatherForecast

A PORO, Plain Old Ruby Object, used to represent normalized forecast data.

It is not an ActiveRecord model because forecast data is temporary and belongs in cache, not in the database.

### Weather::WeatherCodeMapper

Maps external weather codes to human-readable descriptions.

Example:

```ruby
0 => "Clear sky"
```

Unknown codes fall back to:

```text
Unknown
```

### ApplicationResult

A small Result Object used by services.

Services return either:

```ruby
ApplicationResult.success(value)
```

or:

```ruby
ApplicationResult.failure(error)
```

This keeps controllers simple and avoids mixed return types such as `nil`, strings, hashes, or exceptions for expected business failures.

## Cache Strategy

Forecasts are cached by ZIP code:

```text
weather_forecast:90210
```

The cache expires after 30 minutes.

Different addresses with the same ZIP code reuse the same cached forecast, which matches the requirement for subsequent requests by ZIP code.

The submitted address is treated as request context. The weather data is cached by ZIP, but the address displayed to the user comes from the current request.

## Error Handling

Expected failures return controlled `ApplicationResult.failure` responses.

Examples:

* blank address
* missing ZIP code
* ZIP code not found
* external API failure
* invalid API response

The controller displays user-friendly errors instead of exposing low-level exceptions.

## Design Principles

### Single Responsibility

Each class has one clear responsibility:

```text
ForecastsController      -> HTTP request/response
ForecastLookup           -> forecast lookup use case
AddressZipExtractor      -> ZIP parsing
GeocodingClient          -> ZIP to coordinates
ForecastClient           -> coordinates to forecast
WeatherCodeMapper        -> weather code to description
WeatherForecast          -> normalized forecast data
ApplicationResult        -> success/failure contract
```

External API details are isolated in client classes.

### DRY

Cache expiration and cache key generation are centralized in `Weather::ForecastLookup`.

### YAGNI

The app intentionally does not add React, GraphQL, Kafka, background jobs, microservices, or a database table for forecasts because they are not required for this synchronous forecast lookup flow.

### Testability

Most business logic is isolated in small service objects and can be tested without full request specs.
