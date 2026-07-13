# frozen_string_literal: true

require "modelrails_ui/adoption"

namespace :modelrails_ui do
  desc "Report which UI components this app adopts and which are under-audited"
  task adoption: :environment do
    report = ModelrailsUi::Adoption.report(app_root: Rails.root)
    puts ModelrailsUi::Adoption.render_markdown(report, verbose: ENV["VERBOSE"])
  end

  namespace :adoption do
    desc "Adoption report; exit non-zero if any adopted component is under-audited"
    task strict: :environment do
      report = ModelrailsUi::Adoption.report(app_root: Rails.root)
      puts ModelrailsUi::Adoption.render_markdown(report, verbose: ENV["VERBOSE"])
      abort("[adoption] under-audited adopted components found") if report[:blind_spots].any?
    end
  end
end
