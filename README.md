# Weather Forecast App

Ruby on Rails application that accepts an address, extracts a US ZIP code, retrieves weather forecast data, caches the result for 30 minutes, and shows whether the response came from cache. Application fully abstracted. I had some hard times when writing some test use cases. I made the Must-Have test cases. Besides this, I spent a time reading the documentations, and thinking about a good and abstracted architecture. Willing to discuss about the decisions :)

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
- Development-only cache inspector (For easier inspectation)
- RSpec test coverage

## Tech Stack

- Ruby 3.3.4
- Ruby on Rails
- Faraday
- Rails.cache
- RSpec
- WebMock

## Setup

```bash
git clone <repository-url>
cd weather_forecast_assessment
bundle install
bin/rails db:prepare
bin/rails server
````

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

## Example Addresses

```text
Beverly Hills, CA 90210
```

```text
1600 Pennsylvania Ave NW, Washington, DC 20500
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

Main application service.

It coordinates:

* blank address validation
* ZIP extraction
* cache lookup
* geocoding
* forecast retrieval
* cache write
* standardized success/failure response

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

It converts raw API JSON into a normalized `WeatherForecast` object.

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

This keeps controllers simple and avoids mixed return types.

## Cache Strategy

Forecasts are cached by ZIP code:

```text
weather_forecast:90210
```

The cache expires after 30 minutes.

Different addresses with the same ZIP code reuse the same cached forecast, which matches the requirement for subsequent requests by ZIP code.

## Cache Inspector

In development, visit:

```text
http://localhost:3000/cache
```

This page shows local forecast cache entries, including expiration time and a live countdown.

This route should remain development-only and should not be exposed in production.

## Important Trade-offs

This app intentionally supports US ZIP codes only because the requirement is ZIP-based.

It does not attempt full global address parsing or validation. That would require a dedicated address provider and would add unnecessary complexity for this assessment.

The app also does not use React, GraphQL, background jobs, Kafka, or a database because the requested feature is a synchronous Rails flow with short-lived cache behavior.

## Production Considerations

For production, I would consider:

* Redis instead of in-memory cache
* structured logging for external API failures
* metrics around cache hit rate
* API timeout and retry policy
* full address validation if international support is required
* authentication around any internal cache/debug tools
