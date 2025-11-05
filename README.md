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
- ⚠️ **Disclaimer** — This project is mostly vibe coded and in active development. Expect breaking changes and rapid iteration.

## Getting Started

1. Add the gem to your `Gemfile`:
   ```ruby
   gem "rails-assessment"
   ```
   Then run:
   ```bash
   bundle install
   ```

   Or, for development from the git repository:
   ```ruby
   gem "rails-assessment", github: "hmontazeri/rails-assessment"
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
   import AssessmentController from "rails-assessment/controllers/assessment_controller";
   import ThemeToggleController from "rails-assessment/controllers/theme_toggle_controller";
   application.register("assessment", AssessmentController);
   application.register("assessment-theme-toggle", ThemeToggleController);
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

| Option                 | Type              | Default                                                    | Description                                                                |
| ---------------------- | ----------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------- |
| `assessments_paths`    | Array\<Pathname\> | `[Rails.root.join("config", "assessments")]`               | Directories scanned for `.yml` and `.rb` assessment definitions.           |
| `cache_enabled`        | Boolean           | `false` in development, `true` otherwise                   | Toggle reloading of DSL/YAML on each request.                              |
| `fallback_result_text` | String            | `"Thanks for completing the assessment."`                  | Copy returned when no rule matches and no fallback rule exists.            |
| `theme`                | Hash              | See [default theme](lib/rails/assessment/configuration.rb) | Base theme tokens (colors, typography, radius, shadow, dark_mode).         |
| `themes`               | Hash              | `{}`                                                       | Named theme overrides addressable by the resolver (e.g., `?theme=forest`). |
| `theme_strategy`       | Symbol            | `:initializer`                                             | How to resolve the active theme: `:initializer`, `:param`, or `:proc`.     |
| `theme_param_key`      | Symbol/Array      | `:theme`                                                   | Param key(s) inspected when `theme_strategy` is `:param`.                  |
| `theme_proc`           | Proc              | `nil`                                                      | Proc invoked with the current request when `theme_strategy` is `:proc`.    |

At runtime you can access theme tokens in views with `tkn("colors.primary")` or render flattened CSS variables with `assessment_css_variables`.

## Defining Assessments

### YAML

Create files in `config/assessments/*.yml`:

```yaml
title: "Smart Home Check"
slug: "smart-home-check"
hook: "Ist Ihr Zuhause bereit für ein Smart Home?"
description: "Finden Sie in wenigen Fragen heraus, wie gut Ihr Zuhause für Smart-Home-Technologie vorbereitet ist." # Optional
show_start_screen: true # Optional: enables intro screen before first question
estimated_time: "2-3 Minuten" # Optional: displayed on start screen
show_question_count: false # Optional: set to false to hide question count (default: true)
logo: "logo.svg" # Optional: asset path or URL, displays in top right corner
capture_name: true # Optional: capture user's name before results
capture_email: true # Optional: capture user's email before results
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

| Field                 | Type    | Required | Description                                                                                  |
| --------------------- | ------- | -------- | -------------------------------------------------------------------------------------------- |
| `title`               | String  | Yes      | The assessment title displayed in the header.                                                |
| `slug`                | String  | No       | URL-friendly identifier (auto-generated from title if omitted).                              |
| `hook`                | String  | No       | Eyebrow text displayed above the title.                                                      |
| `description`         | String  | No       | Longer description displayed on the start screen (if enabled).                               |
| `show_start_screen`   | Boolean | No       | Enables an intro screen with description, time estimate, and start button. Default: `false`. |
| `estimated_time`      | String  | No       | Time estimate displayed on start screen (e.g., "5 minutes", "2-3 Minuten").                  |
| `show_question_count` | Boolean | No       | Show question count on start screen. Default: `true`.                                        |
| `logo`                | String  | No       | Asset path (e.g., `"logo.svg"`) or full URL. Displays in top right corner (max 120×60px).    |
| `capture_name`        | Boolean | No       | Capture user's name before showing results. Default: `false`.                                |
| `capture_email`       | Boolean | No       | Capture user's email before showing results. Default: `false`.                               |
| `notification_email`  | String  | No       | Email address to notify when a lead is captured. Sends lead details and assessment results.  |
| `webhook_url`         | String  | No       | Webhook URL to POST lead data to when captured. Integrates with Zapier, Make, Notion, etc.   |
| `questions`           | Array   | Yes      | List of question objects (see below).                                                        |
| `result_rules`        | Array   | Yes      | Logic rules for determining results.                                                         |
| `theme`               | Hash    | No       | Per-assessment theme overrides.                                                              |

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
- Successful submissions redirect to `/assessments/:slug/result/:response_uuid`.
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
show_question_count: false # Hide the question count
logo: "company-logo.svg" # or "https://example.com/logo.png" for external URLs
```

The start screen displays:

- Your logo in the top right corner (if provided)
- Assessment title and hook
- Description text
- Info cards showing estimated time (if provided) and/or question count (if enabled)
- A prominent "Start Assessment" button

This creates a more professional first impression and sets user expectations before they begin.

## Lead Capture

Capture user information before showing results to build your email list and personalize the experience:

```yaml
title: "Product Fit Assessment"
capture_name: true # Show name field before results
capture_email: true # Show email field before results
```

When enabled, name and/or email fields appear as the final step before submission. The captured data is stored in the response's `answers` hash under the `lead` key and can be accessed in views:

```erb
<% if user_name(@response).present? %>
  Hello <%= user_name(@response) %>!
<% end %>

<% if user_email(@response).present? %>
  We've sent your results to <%= user_email(@response) %>.
<% end %>
```

## Lead Notifications & Webhooks

Automatically notify yourself and external services when leads are captured:

```yaml
title: "Product Fit Assessment"
capture_email: true
notification_email: "leads@example.com" # Send notification when lead captured
webhook_url: "https://hooks.zapier.com/hooks/catch/..." # Post lead data to webhook
```

When a user completes the assessment with an email captured:

1. **Email Notification**: An email is sent to `notification_email` with the lead's name, email, score, result, and tags
2. **Webhook**: Lead data is POSTed to `webhook_url` as JSON for integration with Zapier, Make, Notion, CRM systems, etc.

### Webhook Payload

The webhook receives a JSON POST with:

```json
{
  "response_id": 123,
  "response_uuid": "2f1b3a0c-6b44-4c6c-8f2c-efa9a917d1d4",
  "assessment_slug": "product-fit",
  "lead": {
    "name": "John Doe",
    "email": "john@example.com"
  },
  "score": 75,
  "result": "Great fit for premium tier",
  "tags": ["qualified", "enterprise"],
  "created_at": "2024-11-04T10:30:00Z",
  "answers": { ... }
}
```

This allows you to:

- Create Zapier/Make automations to add leads to CRMs
- POST directly to Notion databases
- Send data to email marketing platforms
- Trigger webhooks in your own backend
- Build real-time dashboards

No external gems required—uses standard Ruby HTTP library with graceful error handling.

### Configuration Example

```yaml
title: "Smart Home Assessment"
capture_name: true
capture_email: true
notification_email: "sales@company.com"
webhook_url: "https://api.zapier.com/hooks/catch/..."

result_rules:
  - tags: [qualified]
    score_at_least: 80
    text: "You're a great fit!"
    payload:
      cta_text: "Schedule Demo"
      cta_url: "https://calendly.com/company/demo"
```

## Enhanced Result Pages

Create engaging, conversion-focused result pages using the `payload` field in result rules:

```yaml
result_rules:
  - tags: [advanced, goal_compete]
    score_at_least: 60
    text: "Fallback text if payload not used"
    payload:
      headline: "🚀 You're Competition Ready!"
      summary: "You have the experience and commitment to excel..."
      score_message: "Your score indicates exceptional readiness"
      insights:
        - "Your advanced experience puts you ahead of 85% of participants"
        - "Your high commitment shows dedication to improvement"
        - "You have a clear competitive mindset"
      educational_content:
        - "Focus on refining your game plan with a coach"
        - "Study opponent footage to identify patterns"
        - "Practice scenario-based drills regularly"
      # Add custom sections - you can access these in your view!
      next_steps:
        - "Schedule a consultation with our coaching team"
        - "Download the Competition Preparation Guide"
        - "Join our exclusive training community"
      resources:
        - title: "Competition Training Manual"
          url: "https://example.com/manual.pdf"
        - title: "Video: Mental Preparation"
          url: "https://example.com/mental-prep-video"
      cta_text: "Get Your Personalized Training Plan"
      cta_url: "https://calendly.com/coaching/session" # Custom CTA button destination
```

### Built-in Result Page Sections

The enhanced result page automatically displays:

1. **Personalized Greeting**: Shows user's name if captured
2. **Score Visualization**: Animated circular progress indicator
3. **Custom Headline**: From `payload.headline` (supports emoji)
4. **Summary**: From `payload.summary` - brief overview
5. **Score Message**: From `payload.score_message` - contextual score interpretation
6. **Personalized Insights**: From `payload.insights` array - highlighted with checkmarks
7. **Educational Content**: From `payload.educational_content` array - actionable recommendations
8. **Custom CTA**: From `payload.cta_text` - converts better than generic "restart"

- **CTA Destination**: From `payload.cta_url` - redirect button to custom URL (Calendly, contact form, etc.)
- **Default**: If `cta_url` not provided, button defaults to restarting the assessment
- When a custom `cta_url` is supplied, the engine automatically appends `response_uuid` so downstream destinations can correlate results (e.g. `https://calendly.com/acme/demo?response_uuid=...`).
- Lead captures are acknowledged directly on the page, showing the visitor’s name to keep the results feeling personal.

All built-in payload fields are optional. If not provided, the system falls back to displaying the `text` field.

### Adding Custom Sections

You can add any custom fields to the payload and render them in the result view. Edit `app/views/rails/assessment/assessments/result.html.erb` to add additional sections:

```erb
<% next_steps = result_payload(@result_rule, :next_steps, []) %>
<% if next_steps.any? %>
  <div class="result-section result-next-steps-section">
    <h2 class="result-section-title">Next Steps</h2>
    <ol class="result-numbered-list">
      <% next_steps.each do |step| %>
        <li class="result-list-item"><%= step %></li>
      <% end %>
    </ol>
  </div>
<% end %>

<% resources = result_payload(@result_rule, :resources, []) %>
<% if resources.any? %>
  <div class="result-section result-resources-section">
    <h2 class="result-section-title">Recommended Resources</h2>
    <ul class="result-resource-list">
      <% resources.each do |resource| %>
        <li class="result-resource-item">
          <a href="<%= resource[:url] %>" target="_blank" rel="noopener noreferrer">
            <%= resource[:title] %>
          </a>
        </li>
      <% end %>
    </ul>
  </div>
<% end %>
```

Then in your YAML, add these custom fields:

```yaml
payload:
  next_steps:
    - "Schedule a consultation"
    - "Download the guide"
  resources:
    - title: "Resource Title"
      url: "https://example.com"
```

The `result_payload` helper safely accesses nested payload data with optional default values, making it perfect for custom sections you define yourself.

### Helper Methods

Use these helpers in your result views:

```ruby
result_payload(@result_rule, :headline, "Default Headline")  # Access payload data safely
score_percentage(@response.score, 100)                        # Calculate percentage
user_name(@response)                                          # Get captured name
user_email(@response)                                         # Get captured email
```

## Testing

The engine ships with comprehensive Minitest coverage including:

- **Logic Engine Tests** — rule matching and result evaluation
- **YAML/Ruby Loader Tests** — definition parsing and DSL
- **Response Builder Tests** — answer collection and validation
- **Configuration Tests** — theme resolution and settings
- **Lead Notification Mailer Tests** — email generation and delivery
- **Webhook Service Tests** — HTTP payload delivery and error handling
- **Definition Tests** — all configuration fields including lead capture
- **Integration Tests** — full lead capture workflow with emails and webhooks

Run the test suite from the engine root:

```bash
bundle exec rake test
```

The test suite includes 63 tests with 129 assertions, covering all lead capture functionality, email notifications, webhook delivery, and result page customization.

> **Heads-up:** The dummy app depends on `puma`. Ensure it is available in your environment before running the test task.

## License

Released under the MIT License. See `MIT-LICENSE` for details.
