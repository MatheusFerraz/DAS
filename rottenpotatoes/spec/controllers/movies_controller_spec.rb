require 'spec_helper'

describe MoviesController do

  describe 'MoviesHelper method test' do
    it "should returns 'odd' for odd number" do
      factor_sum = 5
      1.upto(100) {|element| oddness(factor_sum + element*2).should eq('odd')}
    end

    it "should returns 'even' for even number" do
       factor_sum = 20
       1.upto(100) {|element| oddness(factor_sum + element*2).should eq('even')}
    end
   end

  describe "GET #index" do
    it "should fills an array of movies" do
      movie = FactoryGirl.create(:movie)
      get :index
      assigns(:movies).should eq([movie])
    end

    it "should loads the :index template" do
      get :index
      response.should render_template :index
    end
   end

   describe "using ratings passed through query string" do
      before :each do
        @firstMovie = FactoryGirl.create(:movie, title: 'TestA', release_date: 11.days.ago, rating: 'G' )
        @secondMovie = FactoryGirl.create(:movie, title: 'TestB', release_date: 9.days.ago, rating: 'R' )
      end

      context "session empty scenario" do
        it "should fills the the session ratings and redirects to movies path" do
          rating_chosen = { 'G' => 'G' }

          get :index, { :ratings => rating_chosen }
          session[:ratings].should eq(rating_chosen)

          response.should be_redirect
          redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
          temp_ratings = redirect_params.select { |p| /^ratings/ =~ p }
          ratings_existing_querystring = Hash[temp_ratings.values.map { |r| [r,r] }]
          expect(ratings_existing_querystring).to eq(rating_chosen)
        end
      end

      context "session filled with the same ratings scenario" do
        it "should shows the movies with the selected ratings" do
          session.stub(:[]).with("flash").and_return double(:sweep => true,
                                                            :update => true,
                                                            :[]= => [],
                                                            :keep => true)
          rating_chosen = { 'G' => 'G' }
          session.stub(:[]).with(:ratings).and_return rating_chosen
          session.stub(:[]).with(:sort).and_return nil
          get :index, { :ratings => rating_chosen }
          assigns(:movies).should eq([@firstMovie])
          response.should render_template :index
        end
      end

      context "session filled with different ratings scenario" do
        it "should fills the session ratings with the new ratings and redirects to movies path" do
          session.stub(:[]).with("flash").and_return double(:sweep => true,
                                                            :update => true,
                                                            :[]= => [],
                                                            :keep => true)
          rating_chosen = { 'R' => 'R' }
          ratings_existing_session = { 'G' => 'G' }
          session.stub(:[]).with(:ratings).and_return ratings_existing_session
          session.stub(:[]).with(:sort).and_return nil
          session.should_receive(:[]=).with("flash", true)
          session.should_receive(:[]=).with(:sort, nil)
          session.should_receive(:[]=).with(:ratings, rating_chosen)

          get :index, { :ratings => rating_chosen }

          response.should be_redirect
          redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
          temp_ratings = redirect_params.select { |p| /^ratings/ =~ p }
          ratings_existing_querystring = Hash[temp_ratings.values.map { |r| [r,r] }]
          expect(ratings_existing_querystring).to eq(rating_chosen)
        end
      end
    end

    describe 'using sort param passed through query string' do
      context 'session empty scenario' do
        it 'should redirects to index with all ratings shown in the query string' do
          get :index, { :sort => 'title' }
          response.should be_redirect

          redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
          temp_ratings = redirect_params.select { |p| /^ratings/ =~ p }
          ratings_existing_querystring = Hash[temp_ratings.values.map { |r| [r,r] }]
          expect(ratings_existing_querystring).to eq(Movie.ratings_hash)
        end
      end

      context 'session filled with ratings and sort' do
        before :each do
          @firstMovie = FactoryGirl.create(:movie, title: 'TestA', release_date: 11.days.ago )
          @secondMovie = FactoryGirl.create(:movie, title: 'TestB', release_date: 9.days.ago )

          session.stub(:[]).with("flash").and_return double(:sweep => true,
                                                            :update => true,
                                                            :[]= => [],
                                                            :keep => true)
          @ratings_to_use = { 'G' => 'G' }
          session.stub(:[]).with(:ratings).and_return @ratings_to_use
        end

        it "should shows movies sorted by title attribute" do
          session.stub(:[]).with(:sort).and_return 'title'
          get :index, { :sort => 'title', :ratings => @ratings_to_use }

          assigns(:movies).should eq([@firstMovie, @secondMovie])
        end

        it "should shows movies sorted by release_date attribute" do
          session.stub(:[]).with(:sort).and_return 'release_date'
          get :index, { :sort => 'release_date', :ratings => @ratings_to_use }

          assigns(:movies).should eq([@firstMovie, @secondMovie])
        end
      end
    end

  describe "GET #show" do
    it "should assigns the requested movie to @movie" do
      movie = FactoryGirl.create(:movie)
      get :show, id: movie
      assigns(:movie).should eq(movie)
    end

    it "should loads the :show template" do
      get :show, id: FactoryGirl.create(:movie)
      response.should render_template :show
    end
  end

  describe "GET #new" do
    it "should loads the :new template" do
      get :new
      response.should render_template :new
    end
  end

  describe "POST #create" do
    it "should create a new movie in the database" do
      expect {
        post :create, movie: FactoryGirl.attributes_for(:movie)
      }.to change(Movie, :count).by(1)
    end

    it "should redirects to the home page" do
      post :create, movie: FactoryGirl.attributes_for(:movie)
      response.should redirect_to movies_path
    end

    it "should shows a success message" do
      movie_params = FactoryGirl.attributes_for(:movie)
      post :create, movie: movie_params
      flash[:notice].should_not be_nil
      flash[:notice].should eq("#{movie_params[:title]} was successfully created.")
    end
  end

  describe "GET #edit" do
    it "should assigns an existing movie to @movie" do
      movie = FactoryGirl.create(:movie)
      get :edit, id: movie
      assigns(:movie).should eq(movie)
    end

    it "should loads the :edit template" do
      movie = FactoryGirl.create(:movie)
      get :edit, id: movie
      response.should render_template :edit
    end
  end

  describe "PUT #update" do
    before :each do
      @movie = FactoryGirl.create(:movie)
    end

    it "should locates an existing movie in the database" do
      put :update, id: @movie, movie: FactoryGirl.attributes_for(:movie)
      assigns(:movie).should eq(@movie)
    end

    it "should updates an existing movie in the database" do
      put :update, id: @movie,
        movie: FactoryGirl.attributes_for(:movie,
                                          title: 'Updated Title',
                                          director: 'Updated Director')
        @movie.reload
        @movie.title.should eq('Updated Title')
        @movie.director.should eq('Updated Director')
    end

    it "should redirects to the home page" do
      put :update, id: @movie, movie: FactoryGirl.attributes_for(:movie)
      response.should redirect_to @movie
    end

    it "should shows a success message" do
      movie_params = FactoryGirl.attributes_for(:movie)
      put :update, id: @movie, movie: FactoryGirl.attributes_for(:movie)

      flash[:notice].should_not be_nil
      flash[:notice].should eq("#{movie_params[:title]} was successfully updated.")
    end
  end

  describe "DELETE #destroy" do
    before :each do
      @movie = FactoryGirl.create(:movie)
    end

    it "should deletes an existing movie from the database" do
      expect {
        delete :destroy, id: @movie
      }.to change(Movie, :count).by(-1)
    end

    it "should redirects to the home page" do
        delete :destroy, id: @movie
        response.should redirect_to movies_path
    end

    it "should shows a success message" do
        delete :destroy, id: @movie
        flash[:notice].should_not be_nil
        flash[:notice].should eq("Movie '#{@movie.title}' deleted.")
    end
  end

  describe "Using same director action" do
    before :each do
      @firstMovie = FactoryGirl.create(:movie)
      @secondMovie = FactoryGirl.create(:movie, director: nil)
    end

    it "should has a URI: /movies/10/same_director" do
      route_expected = '/movies/10/same_director'
      assert_routing(route_expected,
                     { :controller => "movies",
                       :action => "same_director",
                       :id => "10"})
    end

    it "should retrieve the id of the movie from params" do
      get :same_director, id: @firstMovie
      controller.params[:id].should eq(@firstMovie.id.to_s)
      assigns(:movie).should eq(@firstMovie)
    end

    it "should fetch the movie from the database" do
      get :same_director, id: @firstMovie
      assigns(:movie).should eq(@firstMovie)
    end

    it "should calls the method find_movies_with_same_director" do
      Movie.should_receive(:find_movies_with_same_director).with(@firstMovie)
      get :same_director, id: @firstMovie
    end

    it "should loads the same_director view" do
      get :same_director, id: @firstMovie
      response.should render_template :same_director
    end

    it "should redirects to show with an error message if the movie has no director informations" do
      get :same_director, id: @secondMovie
      flash[:notice].should_not be_nil
      flash[:notice].should eq("Movie '#{@secondMovie.title}' does not have informations about the director.")
      response.should be_redirect
    end
  end
end
