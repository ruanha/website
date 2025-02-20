require "application_system_test_case"
require_relative "../../../../support/capybara_helpers"

module Components
  module Mentoring
    module Discussion
      class OutdatedSolutionTest < ApplicationSystemTestCase
        include CapybaraHelpers

        test "mentor sees outdated solution notice" do
          mentor = create :user
          student = create :user
          track = create :track
          exercise = create :concept_exercise, track: track
          solution = create :concept_solution, user: student, exercise: exercise, git_important_files_hash: "outdated"
          request = create :mentor_request, solution: solution
          discussion = create :mentor_discussion, solution: solution, mentor: mentor, request: request
          submission = create :submission, solution: solution
          create :iteration, solution: solution, submission: submission

          use_capybara_host do
            sign_in!(mentor)
            visit mentoring_discussion_path(discussion)
            find(".--status", text: "Outdated").hover

            assert_text "This exercise has been updated since the student submitted this iteration."
          end
        end
      end
    end
  end
end
