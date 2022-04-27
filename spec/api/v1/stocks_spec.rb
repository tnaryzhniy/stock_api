require "rails_helper"

describe V1::Stocks, type: :request do
  let!(:bearer) { FactoryBot.create(:bearer, name: 'Bearer 1') }

  let(:auth_headers) do
    { "Authorization" => "Bearer secure-token" }
  end

  describe 'Unauthenticated' do
    it 'returns Invalid Bearer token error' do
      get '/api/v1/stocks'

      expect(response.status).to eq 401
      expect(response_error).to eq 'Invalid Bearer token'
    end
  end

  describe 'Authenticated' do
    describe 'GET index' do
      let!(:stock1) { FactoryBot.create(:stock, name: 'Stock 1', bearer: bearer) }
      let!(:stock2) { FactoryBot.create(:stock, name: 'Stock 2', bearer: bearer) }

      it 'returns all stocks' do
        get '/api/v1/stocks', headers: auth_headers

        expect(response.status).to eq 200
        expect(response_body.count).to eq(2)
        expect(response_body[0]['name']).to eq stock1.name
        expect(response_body[0]['bearer_name']).to eq bearer.name
      end
    end

    describe 'POST create' do
      let(:stock_params) { { name: 'Stock created', bearer_id: bearer.id } }

      it 'creates new stock' do
        post '/api/v1/stocks', params: stock_params, headers: auth_headers

        expect(response.status).to eq 201
        expect(response_body['name']).to eq stock_params[:name]
        expect(response_body['bearer_name']).to eq bearer.name
      end

      context 'when without without name and bearer id' do
        let(:stock_params) { { name: 'Stock error' } }

        it 'returns param missing error' do
          post '/api/v1/stocks', headers: auth_headers

          expect(response.status).to eq 400
          expect(response_error).to eq 'name is missing, bearer_id is missing'
        end
      end

      context 'when without bearer id' do
        let(:stock_params) { { name: 'Stock error' } }

        it 'returns param missing error' do
          post '/api/v1/stocks', params: stock_params, headers: auth_headers

          expect(response.status).to eq 400
          expect(response_error).to eq 'bearer_id is missing'
        end
      end

      context 'when bearer id is not correct' do
        let(:stock_params) { { name: 'Stock error', bearer_id: 0 } }

        it 'returns not found error' do
          post '/api/v1/stocks', params: stock_params, headers: auth_headers

          expect(response.status).to eq 404
          expect(response_error).to eq "Couldn't find Bearer with 'id'=0"
        end
      end
    end

    describe 'PUT update' do
      subject(:update_stock) do
        put "/api/v1/stocks/#{stock.id}", params: stock_params, headers: auth_headers
      end

      let(:stock) { FactoryBot.create(:stock, name: 'Stock', bearer: bearer) }
      let(:stock_params) { { name: 'Stock updated' } }

      it 'updates a stock' do
        update_stock

        expect(response.status).to eq 200
        expect(response_body['name']).to eq stock_params[:name]
      end

      context 'when empty params' do
        let(:stock_params) { { } }

        it "doesn't update stock" do
          update_stock

          expect(response.status).to eq 200
          expect(response_body['name']).to eq stock.name
        end
      end

      context 'when bearer updated' do
        let(:bearer2) { FactoryBot.create(:bearer, name: 'Bearer 2') }

        context 'when replaced with existing one' do
          let(:stock_params) { { name: 'Stock updated', bearer_name: bearer2.name } }

          it 'updates a bearer name for stock' do
            update_stock

            expect(response.status).to eq 200
            expect(response_body['bearer_name']).to eq bearer2[:name]
          end
        end

        context 'when new bearer created' do
          let(:stock_params) { { bearer_name: 'Bearer 3' } }

          it 'updates a bearer name for stock' do
            expect { update_stock }.to change { Bearer.count }.by(1)
            expect(response.status).to eq 200
            expect(response_body['bearer_name']).to eq 'Bearer 3'
          end
        end
      end

      context 'when stock id is not correct' do
        let(:stock_params) { { name: 'Stock error' } }

        it 'returns param missing error' do
          put "/api/v1/stocks/#{0}", params: stock_params, headers: auth_headers

          expect(response.status).to eq 404
          expect(response_error).to eq "Couldn't find Stock with 'id'=0 [WHERE \"stocks\".\"deleted_at\" IS NULL]"
        end
      end

      context 'when try to update deleted stock' do
        let(:stock) { FactoryBot.create(:stock, name: 'Stock', bearer: bearer, deleted_at: DateTime.current) }
        let(:stock_params) { { name: "Stock won't update" } }

        it "returns Couldn't find error" do
          put "/api/v1/stocks/#{0}", params: stock_params, headers: auth_headers

          expect(response.status).to eq 404
          expect(response_error).to eq "Couldn't find Stock with 'id'=0 [WHERE \"stocks\".\"deleted_at\" IS NULL]"
        end
      end
    end

    describe 'DELETE' do
      let(:stock) { FactoryBot.create(:stock, name: 'Stock', bearer: bearer) }

      subject(:delete_stock) { delete "/api/v1/stocks/#{stock.id}", headers: auth_headers }

      it 'deletes a stock' do
        expect { delete_stock }.not_to change { stock.reload }
        expect(response.status).to eq 204
      end

      context 'when error' do
        let(:stock_params) { { name: 'Stock error' } }

        it "returns Couldn't find error" do
          delete "/api/v1/stocks/#{0}", params: stock_params, headers: auth_headers

          expect(response.status).to eq 404
          expect(response_error).to eq "Couldn't find Stock with 'id'=0 [WHERE \"stocks\".\"deleted_at\" IS NULL]"
        end
      end
    end
  end
end
