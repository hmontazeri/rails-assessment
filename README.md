# Rails Assessment Engine

`rails-assessment` is a mountable Rails 8 engine that lets you ship dynamic, themeable assessments without building CRUD back offices. Define questionnaires in YAML or a Ruby DSL, persist JSONB responses, and deliver a Hotwire-powered multi-step flow that can be embedded in any Rails application.

## Highlights

- **Declarative definitions** — load assessments from YAML files or a compact Ruby DSL.
- **Conditional logic** — evaluate answer tags against ordered rules to produce tailored results.
- **Persistence built-in** — stores submissions in a single `rails_assessment_responses` table (JSONB answers + result text).
- **Hotwire UI** — Turbo Frames + a Stimulus controller provide a progressive multi-step experience with graceful no-JS fallback.
- **Theme system** — inject CSS tokens per assessment, resolve themes via initializer, params, or request proc.

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
        50 => "#F9FAFB",
        900 => "#111827"
      }
    },
    typography: {
      font_sans: "system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif",
      heading: :sans,
      body: :sans
    },
    radius: {
      sm: "0.375rem",
      lg: "0.75rem"
    },
    shadow: {
      card: "0 10px 30px rgba(15, 23, 42, 0.08)"
    },
    dark_mode: {
      enabled: false,
      overrides: {
        colors: {
          neutral: {
            50 => "#0F172A",
            900 => "#E2E8F0"
          }
        }
      }
    }
  }

  config.themes = {
    "forest" => { colors: { primary: "#4A6B52" } }
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

## Rendering & Flow

- `GET /assessments/:slug` renders the multi-step form.
- Submission posts to `/assessments/:slug/response` (local form, Turbo friendly).
- Successful submissions redirect to `/assessments/:slug/result?response_id=...`.
- Responses are stored in `Rails::Assessment::Response` with aggregated tags and score helpers.

The Stimulus controller manages step transitions, validates required steps, and keeps a progress bar in sync. Without JavaScript the form gracefully falls back to a stacked layout via CSS.

## Logic Engine

`Rails::Assessment::LogicEngine.evaluate(tags, rules, score: nil)` walks ordered rules and returns the first match. Rules support:

- `tags` / `all_tags` — all tags must be present.
- `any_tags` — at least one tag must match.
- `exclude_tags` — block rules when tags intersect.
- `score_at_least` / `score_at_most` — numeric guards.
- `fallback` — designated catch-all rule.

## Testing

The engine ships with Minitest coverage for the logic engine, YAML/Ruby loaders, response builder, and configuration. Run the suite from the engine root:

```bash
bundle exec rake test
```

> **Heads-up:** The dummy app depends on `puma`. Ensure it is available in your environment before running the test task.

## License

Released under the MIT License. See `MIT-LICENSE` for details.
