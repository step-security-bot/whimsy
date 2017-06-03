#
# Draft an "Establish" resolution for a new PMC
#

class PPMCGraduate < React
  def initialize
    @owners = []
  end

  def render
    _button.btn.btn_info 'Draft graduation resolution',
      data_target: '#graduate', data_toggle: 'modal'

    _div.modal.fade.graduate! tabindex: -1 do
      _div.modal_dialog do
        _div.modal_content do
          _form method: 'post', action: "ppmc/#{@@ppmc.id}/establish" do
	    _div.modal_header.bg_info do
	      _button.close 'x', data_dismiss: 'modal'
	      _h4.modal_title "Establish Apache #{@project}"
	    end

	    _div.modal_body do
	      _p do
		_b 'Complete this sentence: '
		_span "Apache #{@project} consists of software related to"
	      end

	      _textarea name: 'description', value: @description, rows: 4

	      _p { _b 'Choose a chair' }

	      _select name: 'chair' do
		@owners.each do |person|
		  _option person.name, value: person.id,
		    selected: person.id == @@id
		end
	      end
	    end

	    _div.modal_footer do
	      _span.status 'Processing request...' if @disabled
	      _button.btn.btn_default 'Cancel', data_dismiss: 'modal'
	      _button.btn.btn_primary 'Draft Resolution'
	    end
          end
        end
      end
    end
  end

  def componentDidMount()
    textarea = jQuery('#graduate textarea')

    jQuery('#graduate').on('show.bs.modal') do |event|
      @project = @@ppmc.display_name
      @description = @@ppmc.description

      textarea.css('height', 0)
      textarea.css('height',Math.max(50, textarea[0].scrollHeight)+'px')

      @owners = @@ppmc.owners.
        map {|id| {id: id, name: @@ppmc.roster[id].name}}.
        sort_by {|person| person.name}
    end

    textarea.on('keyup') do |event|
      textarea.css('height', 0)
      textarea.css('height', Math.max(50, textarea[0].scrollHeight)+'px')
    end
  end
end
