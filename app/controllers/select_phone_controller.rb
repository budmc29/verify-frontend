class SelectPhoneController < ApplicationController
  def index
    @form = SelectPhoneForm.new({})
  end

  def select_phone
    @form = SelectPhoneForm.new(params['select_phone_form'] || {})
    if @form.valid?
      report_to_analytics('Phone Next')
      selected_answer_store.store_selected_answers('phone', @form.selected_answers)
      if idp_eligibility_checker.any?(selected_evidence, current_identity_providers)
        redirect_to choose_a_certified_company_path
      else
        redirect_to no_mobile_phone_path
      end
    else
      flash.now[:errors] = @form.errors.full_messages.join(', ')
      render :index
    end
  end

  def no_mobile_phone
    @other_ways_description = current_transaction.other_ways_description
    @other_ways_text = current_transaction.other_ways_text
  end

private

  def idp_eligibility_checker
    if is_in_b_group?
      IDP_ELIGIBILITY_CHECKER_B
    else
      IDP_ELIGIBILITY_CHECKER
    end
  end
end
