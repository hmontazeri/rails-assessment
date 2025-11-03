Rails::Assessment.configure do |config|
  config.assessments_paths = [
    Rails.root.join("config", "assessments")
  ]

  config.theme = {
    colors: {
      primary: "#2563EB",
      neutral: { 50 => "#F8FAFC", 900 => "#0F172A" },
      accent: "#FACC15"
    },
    typography: {
      font_sans: "'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
      font_serif: "'Merriweather', serif",
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
      enabled: true,
      primary: "#7DD3FC"
    }
  }

  config.themes = {
    "forest" => {
      colors: {
        primary: "#4A6B52",
        neutral: { 50 => "#F5F9F5", 900 => "#1F3324" }
      }
    },
    "midnight" => {
      colors: {
        primary: "#79A586",
        neutral: { 50 => "#0F172A", 900 => "#020617" }
      },
      dark_mode: {
        enabled: true
      }
    }
  }

  config.theme_strategy = :param
  config.theme_param_key = :theme
  config.fallback_result_text = "We have received your responses. Our team will follow up soon."
end
