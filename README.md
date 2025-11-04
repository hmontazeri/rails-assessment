# Rails Assessment Engine

`rails-assessment` is a mountable Rails 8 engine that lets you ship dynamic, themeable assessments without building CRUD back offices. Define questionnaires in YAML or a Ruby DSL, persist JSONB responses, and deliver a Hotwire-powered multi-step flow that can be embedded in any Rails application.

## Highlights

- **Declarative definitions** — load assessments from YAML files or a compact Ruby DSL.
- **Conditional logic** — evaluate answer tags against ordered rules to produce tailored results.
- **Persistence built-in** — stores submissions in a single `rails_assessment_responses` table (JSONB answers + result text).
- **Hotwire UI** — Turbo Frames + a Stimulus controller provide a progressive multi-step experience with graceful no-JS fallback.
- **Theme system** — inject CSS tokens per assessment, resolve themes via initializer, params, or request proc.
- **Dark mode support** — optional dark mode toggle with customizable theme variables.
- **Start screen** — optional intro screen with description, estimated time, and branding.

## Getting Started

1. Add the gem to your host app (or use it as an engines workspace dependency):
   ```ruby
   gem "rails-assessment", path: "path/to/rails-assessment"
   ```
2. Mount the engine in `config/routes.rb`:
   ```ruby
   Rails.application.routes.draw do
     mount Rails::Assessment::Engine => "/assessments"
   end
   ```
3. Install the migration and run it:
   ```bash
   bin/rails railties:install:migrations
   bin/rails db:migrate
   ```
4. Create `config/initializers/rails_assessment.rb` (see example below) and drop YAML files into `config/assessments/`.
5. Pin and import the Stimulus controller so Hotwire can register it (Importmap example):
   ```ruby
   # config/importmap.rb
   pin "rails-assessment/controllers/assessment_controller", to: "rails/assessment/controllers/assessment_controller.js"
   pin "rails-assessment/controllers/theme_toggle_controller", to: "rails/assessment/controllers/theme_toggle_controller.js"
   ```
   ```javascript
   // app/javascript/controllers/index.js
   import AssessmentController from "rails-assessment/controllers/assessment_controller"
   import ThemeToggleController from "rails-assessment/controllers/theme_toggle_controller"
   application.register("assessment", AssessmentController)
   application.register("assessment-theme-toggle", ThemeToggleController)
   ```
6. Visit `http://localhost:3000/assessments/<slug>` to see the assessment in action.

## Configuration

The engine ships with a configuration object accessible via `Rails::Assessment.configure`.

```ruby
# config/initializers/rails_assessment.rb
Rails::Assessment.configure do |config|
  config.assessments_paths = [Rails.root.join("config", "assessments")]
  config.theme_strategy = :param
  config.theme_param_key = :theme

  config.theme = {
    colors: {
      primary: "#2563EB",
      neutral: {
        50 => "#F8FAFC",
        900 => "#0F172A"
      }
    },
    typography: {
      font_sans: "system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif",
      heading: :sans,
      body: :sans
    },
    radius: {
      sm: "0.5rem",
      lg: "1rem"
    },
    shadow: {
      card: "0 20px 45px rgba(15, 23, 42, 0.12)"
    },
    dark_mode: {
      enabled: true,        # Enable dark mode toggle
      default: :light,      # Default theme (:light or :dark)
      overrides: {
        colors: {
          neutral: {
            50 => "#0F172A",    # Dark background
            900 => "#F8FAFC"    # Light text
          }
        }
      }
    }
  }

  config.themes = {
    "forest" => {
      colors: {
        primary: "#4A6B52",
        accent: "#F1B722"
      }
    }
  }

  config.fallback_result_text = "Thanks for completing the assessment."
end
```

| Option              | Type              | Default                                                  | Description                                                                                  |
| ------------------- | ----------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `assessments_paths` | Array\<Pathname\> | `[Rails.root.join("config", "assessments")]`             | Directories scanned for `.yml` and `.rb` assessment definitions.                             |
| `cache_enabled`     | Boolean           | `false` in development, `true` otherwise                 | Toggle reloading of DSL/YAML on each request.                                               |
| `fallback_result_text` | String        | `"Thanks for completing the assessment."`                | Copy returned when no rule matches and no fallback rule exists.                              |
| `theme`             | Hash              | See [default theme](lib/rails/assessment/configuration.rb) | Base theme tokens (colors, typography, radius, shadow, dark_mode).                           |
| `themes`            | Hash              | `{}`                                                     | Named theme overrides addressable by the resolver (e.g., `?theme=forest`).                   |
| `theme_strategy`    | Symbol            | `:initializer`                                           | How to resolve the active theme: `:initializer`, `:param`, or `:proc`.                       |
| `theme_param_key`   | Symbol/Array      | `:theme`                                                 | Param key(s) inspected when `theme_strategy` is `:param`.                                    |
| `theme_proc`        | Proc              | `nil`                                                    | Proc invoked with the current request when `theme_strategy` is `:proc`.                      |

At runtime you can access theme tokens in views with `tkn("colors.primary")` or render flattened CSS variables with `assessment_css_variables`.

## Defining Assessments

### YAML

Create files in `config/assessments/*.yml`:

```yaml
title: "Smart Home Check"
slug: "smart-home-check"
hook: "Ist Ihr Zuhause bereit für ein Smart Home?"
description: "Finden Sie in wenigen Fragen heraus, wie gut Ihr Zuhause für Smart-Home-Technologie vorbereitet ist."  # Optional
show_start_screen: true  # Optional: enables intro screen before first question
estimated_time: "2-3 Minuten"  # Optional: displayed on start screen
logo: "logo.svg"  # Optional: asset path or URL, displays in top right corner
questions:
  - text: "Haben Sie WLAN in allen Räumen?"
    options:
      - text: "Ja"
        tag: wifi_ok
        score: 2
      - text: "Nein"
        tag: wifi_bad
        score: 0
result_rules:
  - tags: [wifi_ok]
    text: "Perfekt!"
  - fallback: true
    text: "Wir melden uns mit Empfehlungen."
```

### Ruby DSL

```ruby
Rails::Assessment.define "smart-home" do
  title "Smart Home Check"
  hook "Ist Ihr Zuhause bereit für ein Smart Home?"

  question "Haben Sie WLAN in allen Räumen?" do
    option "Ja", tag: :wifi_ok, score: 2
    option "Nein", tag: :wifi_bad
  end

  result_rule "Perfekt!" do
    tags :wifi_ok
  end

  fallback "Wir melden uns mit Empfehlungen."
end
```

The loader watches these files in development (no caching) and reloads automatically on request.

### Assessment Options

| Field                | Type    | Required | Description                                                                                     |
| -------------------- | ------- | -------- | ----------------------------------------------------------------------------------------------- |
| `title`              | String  | Yes      | The assessment title displayed in the header.                                                   |
| `slug`               | String  | No       | URL-friendly identifier (auto-generated from title if omitted).                                 |
| `hook`               | String  | No       | Eyebrow text displayed above the title.                                                         |
| `description`        | String  | No       | Longer description displayed on the start screen (if enabled).                                  |
| `show_start_screen`  | Boolean | No       | Enables an intro screen with description, time estimate, and start button. Default: `false`.    |
| `estimated_time`     | String  | No       | Time estimate displayed on start screen (e.g., "5 minutes", "2-3 Minuten").                     |
| `logo`               | String  | No       | Asset path (e.g., `"logo.svg"`) or full URL. Displays in top right corner (max 120×60px).       |
| `questions`          | Array   | Yes      | List of question objects (see below).                                                           |
| `result_rules`       | Array   | Yes      | Logic rules for determining results.                                                            |
| `theme`              | Hash    | No       | Per-assessment theme overrides.                                                                 |

### Question Options

Each question supports:
- `text` (required) — The question prompt.
- `help_text` (optional) — Additional context displayed below the question.
- `required` (optional) — Whether answer is required. Default: `true`.
- `multi_select` (optional) — Allow multiple answers (checkboxes vs radios). Default: `false`.
- `options` (required) — Array of answer options with `text`, `tag`, `score`, etc.

## Rendering & Flow

- `GET /assessments/:slug` renders the assessment (start screen or first question).
- If `show_start_screen: true`, displays intro with description, time estimate, and "Start Assessment" button.
- Clicking start button smoothly transitions to the first question with fade animation.
- The Stimulus controller manages step transitions, validates required steps, and keeps a progress bar in sync.
- Submission posts to `/assessments/:slug/response` (local form, Turbo friendly).
- Successful submissions redirect to `/assessments/:slug/result?response_id=...`.
- Responses are stored in `Rails::Assessment::Response` with aggregated tags and score helpers.

Without JavaScript the form gracefully falls back to a stacked layout via CSS.

## Logic Engine

`Rails::Assessment::LogicEngine.evaluate(tags, rules, score: nil)` walks ordered rules and returns the first match. Rules support:

- `tags` / `all_tags` — all tags must be present.
- `any_tags` — at least one tag must match.
- `exclude_tags` — block rules when tags intersect.
- `score_at_least` / `score_at_most` — numeric guards.
- `fallback` — designated catch-all rule.

## Dark Mode

The engine includes built-in dark mode support. Enable it in your theme configuration:

```ruby
Rails::Assessment.configure do |config|
  config.theme = {
    # ... other theme settings
    dark_mode: {
      enabled: true,  # Enables the dark mode toggle button
      default: :light,  # or :dark to default to dark mode
      overrides: {
        colors: {
          neutral: {
            50 => "#0F172A",   # Dark background
            900 => "#E2E8F0"   # Light text
          }
        }
      }
    }
  }
end
```

When enabled, a floating toggle button appears in the bottom left corner. User preference is persisted to `localStorage`. The dark mode uses CSS variables that can be customized per assessment via the theme system.

## Start Screen & Branding

Enhance the user experience with an optional start screen:

```yaml
title: "Product Fit Assessment"
description: "Answer a few quick questions to see if our product is right for you."
show_start_screen: true
estimated_time: "3-5 minutes"
logo: "company-logo.svg"  # or "https://example.com/logo.png" for external URLs
```

The start screen displays:
- Your logo in the top right corner (if provided)
- Assessment title and hook
- Description text
- Info cards showing estimated time and question count
- A prominent "Start Assessment" button

This creates a more professional first impression and sets user expectations before they begin.

## Testing

The engine ships with Minitest coverage for the logic engine, YAML/Ruby loaders, response builder, and configuration. Run the suite from the engine root:

```bash
bundle exec rake test
```

> **Heads-up:** The dummy app depends on `puma`. Ensure it is available in your environment before running the test task.

## License

Released under the MIT License. See `MIT-LICENSE` for details.
