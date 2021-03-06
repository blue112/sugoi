package sugoi.form.elements;

import sugoi.Web;
import sugoi.form.FormElement;
import sugoi.form.validators.Validator;
import sugoi.form.ListData;

/**
 * A list of selectBox for day + month + year
 */
class DateDropdowns extends FormElement<Date>
{
	public var maxOffset:Int;
	public var minOffset:Int;

	//public var date : Date; //valeur typée à la place de value:Dynamic

	public var yearMin:Int;
	public var yearMax:Int;

	private var daySelector:Selectbox<Int>;
	private var monthSelector:Selectbox<Int>;
	private var yearSelector:Selectbox<Int>;

	public function new(name:String, label:String, ?_value:Date, ?required:Bool=false, yearMin:Int=1950, yearMax:Int=null, ?validators:Array<Validator<Date>>, ?attibutes:String="")
	{
		super();
		this.name = name;
		this.label = label;

		if (_value == null) {
			value = Date.now();
		}else {
			value = _value;
		}

		this.required = required;
		this.attributes = attibutes;
		this.yearMin = yearMin;
		this.yearMax = yearMax;

		maxOffset = null;
		minOffset = null;

		var day :Int = null;
		var month :Int = null;
		var year :Int = null;

		if (value != null)
		{
			day = 	value.getDate();
			month = (value.getMonth()+1);
			year = 	value.getFullYear();
		}

		var t = sugoi.form.Form.translator;
		daySelector = 	new IntSelect(name+"_day", t._("day"),ListData.getDays(),day,true);
		monthSelector = new IntSelect(name+"_month", t._("month"),ListData.getMonths(),month,true);
		yearSelector = 	new IntSelect(name+"_year", t._("year"), ListData.getYears(Date.now().getFullYear()-3, Date.now().getFullYear()+3, true), year, true);

		daySelector.internal = monthSelector.internal = yearSelector.internal = true;

		//if (Form.USE_TWITTER_BOOTSTRAP) {
			//daySelector.cssClass = "input-mini";
		//}
		//trace("date : " + date);
	}
	public function shortLabels()
	{
		daySelector.nullMessage = "-D-";
		monthSelector.nullMessage = "-M-";
		yearSelector.nullMessage = "-Y-";
		monthSelector.data = ListData.getMonths(true);
	}

	override public function init()
	{
		super.init();

		parentForm.addElement(daySelector);
		parentForm.addElement(monthSelector);
		parentForm.addElement(yearSelector);
	}

	override public function populate()
	{

		var day = Std.parseInt(App.current.params.get(parentForm.name + "_" + daySelector.name));
		var month = Std.parseInt(App.current.params.get(parentForm.name + "_" + monthSelector.name));
		var year = Std.parseInt(App.current.params.get(parentForm.name + "_" + yearSelector.name));

		value = (day != null && month != null && year != null ) ? new Date(year, month - 1, day, 0, 0, 0) : null;
	}

	override public function isValid():Bool
	{
		/*var valid = super.isValid();

		if ( required && valid )
		{
			var n = form.name + "_" + name;
			var day = Std.parseInt(App.current.params.get(n));
			var month = Std.parseInt(App.current.params.get(n));
			var year = Std.parseInt(App.current.params.get(n));

			if (day == null || month == null || year == null )
			{
				errors.add("<span class=\"formErrorsField\">" + ((label != null && label != "") ? label : name) + "</span> is an invalid date.");
				return false;
			}
			return true;
		}

		return valid;*/
		return true;
	}



	override public function render():String
	{
		super.render();
		
		if (value != null)
		{
			try{
			var v:Date = cast value;
			daySelector.value = v.getDate();
			monthSelector.value = v.getMonth()+1;
			yearSelector.value = v.getFullYear();
			}catch(e:Dynamic){}
		}
		
		return '<div class="row">
		  <div class="col-xs-2">'+daySelector.render()+'</div>
		  <div class="col-xs-6">'+monthSelector.render()+'</div>
		  <div class="col-xs-4">'+yearSelector.render()+'</div>
		</div>';
	}


}