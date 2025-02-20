require_relative '../base_test_case'

class API::Solutions::SubmissionFilesControllerTest < API::BaseTestCase
  ###
  # INDEX
  ###

  test "index should return 404 when submission doesnt exist" do
    setup_user

    get api_solution_submission_files_path(create(:concept_solution).uuid, 1),
      headers: @headers,
      as: :json

    assert_response 404
    expected = { error: {
      type: "submission_not_found",
      message: I18n.t('api.errors.submission_not_found')
    } }
    actual = JSON.parse(response.body, symbolize_names: true)
    assert_equal expected, actual
  end

  test "index should return 404 when submission is inaccessible" do
    setup_user
    submission = create :submission

    get api_solution_submission_files_path(submission.solution.uuid, submission),
      headers: @headers,
      as: :json

    assert_response 403
    expected = { error: {
      type: "submission_not_accessible",
      message: I18n.t('api.errors.submission_not_accessible')
    } }
    actual = JSON.parse(response.body, symbolize_names: true)
    assert_equal expected, actual
  end

  test "index should return files" do
    mentor = create :user
    setup_user(mentor)
    solution = create :concept_solution
    iteration = create :iteration, solution: solution
    create :mentor_discussion, solution: solution, mentor: mentor
    submission = create :submission, solution: solution, iteration: iteration
    file = create :submission_file, filename: "bob.rb", content: "class Bob", submission: submission

    sign_in(mentor)
    get api_solution_submission_files_path(solution.uuid, submission),
      headers: @headers,
      as: :json

    assert_response 200
    expected = {
      files: [
        {
          filename: "bob.rb",
          content: "class Bob",
          digest: file.digest
        }
      ]
    }
    actual = JSON.parse(response.body, symbolize_names: true)
    assert_equal expected, actual
  end
end
