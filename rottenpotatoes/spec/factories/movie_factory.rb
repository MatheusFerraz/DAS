FactoryGirl.define do
	factory :movie do
		title "Test Title"
		rating "G"
		director "Test Director"
		release_date {11.day.ago}
	end
end
