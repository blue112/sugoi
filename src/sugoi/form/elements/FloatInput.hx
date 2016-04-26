package sugoi.form.elements;
import sugoi.form.filters.FloatFilter;

class FloatInput extends Input<Float>
{
	
	public function new(name, label, value, ?required=false){
		super(name, label, value, required);
	}
	
	override public function getTypedValue(str:String):Float{
		var f = new FloatFilter();
		return f.filter(str);
		
	}
	
}