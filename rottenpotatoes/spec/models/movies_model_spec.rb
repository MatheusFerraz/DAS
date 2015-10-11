require 'spec_helper'

describe Movie do

	it 'should has a valid factory' do
		FactoryGirl.create(:movie).should be_valid
	end

	describe 'simple read operations definition' do
		context 'happy paths' do
			before :each do
				@movie_instance = FactoryGirl.create(:movie, title: 'testMovie')
			end

			it 'should finds movies by id' do
				Movie.find_by_id(1).should_not be_nil
			end

			it 'should finds movies by title' do
				Movie.find_by_title('testMovie').should_not be_nil
			end
		end

		context 'sad paths' do
			before :each do
				@movie_instance = FactoryGirl.create(:movie, title: 'testMovie')
			end

			it 'should finds movies by id (unsuccessfully)' do
				Movie.find_by_id(50).should be_nil
			end

			it 'should finds movies by title (unsuccessfully)' do
				Movie.find_by_title('nonexistentMovie').should be_nil
			end
		end
	end
end

describe 'finds movies with the same director' do
    	before :each do
      		@firstMovie = FactoryGirl.create(:movie, director: 'First Director')
      		@secondMovie = FactoryGirl.create(:movie, director: 'First Director')
      		@thirdMovie = FactoryGirl.create(:movie, director: 'Second Director')
      		@fourthMovie = FactoryGirl.create(:movie, director: 'Third Director')
    	end

   		context 'movies with the same director' do
     			 it 'should returns all the movies with the same director' do
        			director_to_search = 'First Director'
        			movie = FactoryGirl.create(:movie, director: director_to_search)
        			search_result = Movie.find_movies_with_same_director(movie)
        			search_result.count.should eq(3)
        			search_result.map { |m| m.director }.each { |d| d.should eq(director_to_search) }
      			end
    		end
    
		context "movies with director only one occurrence" do
      			it 'returns just this movie' do
        			movie = FactoryGirl.create(:movie, director: 'Director Y')
        			search_result = Movie.find_movies_with_same_director(movie)
        			search_result.count.should eq(1)
        			search_result.should eq([movie])
     			 end
    		end
end
