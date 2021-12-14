class Submission
  class TestRun
    class Init
      include Mandate

      def initialize(submission, type: :submission, git_sha: nil, run_in_background: false)
        @submission = submission
        @type = type.to_sym
        @git_sha = git_sha || submission.git_sha
        @run_in_background = !!run_in_background
      end

      def call
        ToolingJob::Create.(
          :test_runner,
          submission.uuid,
          solution.track.slug,
          solution.exercise.slug,
          run_in_background: run_in_background,
          source: {
            submission_efs_root: submission.uuid,
            submission_filepaths: submission.valid_filepaths,
            exercise_git_repo: solution.track.slug,
            exercise_git_sha: git_sha,
            exercise_git_dir: exercise_repo.dir,
            exercise_filepaths: exercise_filepaths
          }
        ).tap do
          update_status!
        end
      end

      private
      attr_reader :submission, :git_sha, :type, :run_in_background

      # rubocop:disable Style/IfUnlessModifier
      # rubocop:disable Style/GuardClause
      def update_status!
        return submission.tests_queued! unless type == :solution

        if submission == solution.latest_submission
          submission.solution.update_latest_iteration_head_tests_status!(:queued)
        end

        if submission == solution.latest_published_iteration_submission
          submission.solution.update_published_iteration_head_tests_status!(:queued)
        end
      end
      # rubocop:enable Style/GuardClause
      # rubocop:enable Style/IfUnlessModifier

      memoize
      delegate :solution, to: :submission

      def exercise_filepaths
        exercise_repo.tooling_filepaths.select do |filepath|
          # Skip non-functional files
          next false if filepath.starts_with?(".docs")
          next false if filepath == "README.md"

          # Skip submitted files
          next false if submission.valid_filepaths.include?(filepath)

          true
        end
      end

      memoize
      def exercise_repo
        Git::Exercise.new(
          solution.git_slug,
          solution.git_type,
          git_sha,
          repo_url: solution.track.repo_url
        )
      end
    end
  end
end
