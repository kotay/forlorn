class GentlemenController < ApplicationController
  def index
    @gentlemen = current_user.gentlemen.page(params[:page])

    respond_to do |format|
      format.html
      format.json { render json: @gentlemen }
    end
  end

  def run
    Gentleman.async_check(current_user.gentlemen.find(params[:id]).id)
    redirect_to gentlemen_path, notice: "Gentleman run queued"
  end

  def type_details
    gentleman = Gentleman.build_for_type(params[:type], current_user, {})
    render :json => {
        :can_be_scheduled => gentleman.can_be_scheduled?,
        :can_receive_events => gentleman.can_receive_events?,
        :options => gentleman.default_options,
        :description_html => gentleman.html_description
    }
  end

  def event_descriptions
    html = current_user.gentlemen.find(params[:ids].split(",")).group_by(&:type).map { |type, gentlemen|
      gentlemen.map(&:html_event_description).uniq.map { |desc|
        "<p><strong>#{type}</strong><br />" + desc + "</p>"
      }
    }.flatten.join()
    render :json => { :description_html => html }
  end

  def remove_events
    @gentleman = current_user.gentlemen.find(params[:id])
    @gentleman.events.delete_all
    redirect_to gentlemen_path, notice: "All events removed"
  end

  def propagate
    details = Gentleman.receive!
    redirect_to gentlemen_path, notice: "Queued propagation calls for #{details[:event_count]} event(s) on #{details[:gentleman_count]} gentlemen(s)"
  end

  def show
    @gentleman = current_user.gentlemen.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: @gentleman }
    end
  end

  def new
    @gentleman = current_user.gentlemen.build

    respond_to do |format|
      format.html
      format.json { render json: @gentleman }
    end
  end

  def edit
    @gentleman = current_user.gentlemen.find(params[:id])
  end

  def diagram
    @gentlemen = current_user.gentlemen.includes(:receivers)
  end

  def create
    @gentleman = Gentleman.build_for_type(params[:gentleman].delete(:type),
                                  current_user,
                                  params[:gentleman])
    respond_to do |format|
      if @gentleman.save
        format.html { redirect_to gentlemen_path, notice: 'Your Gentleman was successfully created.' }
        format.json { render json: @gentleman, status: :created, location: @gentleman }
      else
        format.html { render action: "new" }
        format.json { render json: @gentleman.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @gentleman = current_user.gentlemen.find(params[:id])

    respond_to do |format|
      if @gentleman.update_attributes(params[:gentleman])
        format.html { redirect_to gentlemen_path, notice: 'Your Gentleman was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @gentleman.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @gentleman = current_user.gentlemen.find(params[:id])
    @gentleman.destroy

    respond_to do |format|
      format.html { redirect_to gentlemen_path }
      format.json { head :no_content }
    end
  end
end
