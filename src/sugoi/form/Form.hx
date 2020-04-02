package sugoi.form;

import haxe.crypto.Md5;
import sugoi.form.elements.Input;
import sugoi.i18n.translator.ITranslator;
import sugoi.form.elements.*;
import sugoi.Web;
import sys.db.Types;
import sys.db.Object;
import sys.db.Manager;

enum FormMethod
{
	GET;
	POST;
}

class Form
{
	public var id:String;
	public var name:String;
	public var action:String;
	public var method:FormMethod;
	public var elements:Array<FormElement<Dynamic>>;
	public var fieldsets:Map<String,FieldSet>;
	public var forcePopulate:Bool;		//the form is populated by web params if isValid() is called
	public var submitButton:FormElement<String>;
	private var extraErrors:List<String>;
	public var requiredClass:String;
	public var requiredErrorClass:String;
	public var invalidErrorClass:String;
	public var labelRequiredIndicator:String;
	public var defaultClass : String;
	public var multipart:Bool;

	public static var translator : ITranslator;

	//submit button
	public var submitButtonLabel:String;
	public var autoGenSubmitButton:Bool;	//add a submit button automatically

	//conf
	public static var USE_TWITTER_BOOTSTRAP = true;
	public static var USE_DATEPICKER = true; //http://eonasdan.github.io/bootstrap-datetimepicker/

	public function new(name:String, ?action:String, ?method:FormMethod)
	{
		requiredClass = "formRequired";
		requiredErrorClass = "formRequiredError";
		invalidErrorClass = "formInvalidError";
		labelRequiredIndicator = " *";
		defaultClass = Form.USE_TWITTER_BOOTSTRAP ? "form-horizontal":"";

		forcePopulate = true;
		multipart = false;
		autoGenSubmitButton = true;

		this.id = name;
		this.name = name;

		if (action == null) {
			this.action = Web.getURI();
		}else {
			this.action = action;
		}

		this.method = (method == null) ? FormMethod.POST : method;

		elements = new Array();
		extraErrors = new List();
		fieldsets = new Map();
		addFieldset("__default", new FieldSet("__default", "Default", false));

		addElement(new CSRFProtection());

		toString = render;
	}

	/**
	 * Adds a form element to the form
	 * @param	element
	 * @param	?fieldSetKey	Add it to a specific fieldset
	 * @param 	?index			which index do u want to push it
	 * @return
	 */
	public function addElement(element:FormElement<Dynamic>,?index:Int, ?fieldSetKey:String = "__default"):FormElement<Dynamic>
	{
		element.parentForm = this;
		if (index != null) {
			var out = elements.slice(0, index);
			out = out.concat([element]);
			out = out.concat(elements.slice(index));
			elements = out;
		}else {
			elements.push(element);
		}

		// add it to a group if requested
		if (fieldSetKey != null){
			if (!fieldsets.exists(fieldSetKey)) throw "No fieldset '" + fieldSetKey + "' exists in '" + name + "' form.";
			fieldsets.get(fieldSetKey).elements.push(element);
		}

		//if ( Std.is(element, RichtextWym) )
			//wymEditorCount++;

		return element;
	}

	public function removeElement(element:FormElement<Dynamic>):Bool
	{
		if ( elements.remove(element) )
		{
			element.parentForm= null;
			for ( fs in fieldsets )
			{
				fs.elements.remove(element);
			}

			//if ( Std.is(element, RichtextWym) )
				//wymEditorCount--;
			return true;
		}
		return false;
	}

	public function setSubmitButton(el:FormElement<String>):FormElement<String>
	{
		submitButton = el;
		submitButton.parentForm = this;
		return el;
	}

	public function addFieldset(fieldSetKey:String, fieldSet:FieldSet)
	{
		fieldSet.form = this;
		fieldsets.set(fieldSetKey, fieldSet);
	}

	public function getFieldsets():Map<String,FieldSet>
	{
		return fieldsets;
	}

	public function getLabel( elementName : String ) : String
	{
		return getElement( elementName ).getLabel();
	}

	public function getElement(name:String):FormElement<Dynamic> {
		if (name == null || name=='') throw "Element name is null";
		for (element in elements){
			if (element.name == name) return element;
		}
		return null;
	}

	public function removeElementByName(name:String) {
		var e = getElement(name);
		if (e != null) removeElement(e);
	}

	/**
	 * Get the typed value of a form element.
	 * The value can be of any type !
	 *
	 * @param	elementName
	 * @return
	 */
	public function getValueOf(elementName:String):Dynamic {
		return getElement(elementName).value;
	}

	public function getElementTyped<T>(name:String, type:Class<T>):T{
		var o:T = cast(getElement(name));
		return o;
	}

	/**
	 * return datas contained in current form elements
	 * @return
	 */
	public function getData():Map<String,Dynamic>
	{
		var data = new Map<String,Dynamic>();
		for (element in getElements()){
			if (element.name == null) throw "Element has no name : "+element.toString();
			data.set( element.name,element.getValue() );
		}
		return data;
	}

	/**
	 * return datas in an anonymous object
	 * @return
	 */
	public function getDatasAsObject():Dynamic {

		var data = { };
		for ( el in elements) {
			Reflect.setField(data, el.name, el.value);
		}
		return data;

	}

	/**
	 * populate Form from anonymous object or if null from web params.
	 * @param	custom
	 */
	public function populate(?custom:Dynamic){
		if (custom != null)	{
			//from object
			for (element in getElements()) {
				var n = element.name;
				var v = Reflect.field(custom, n);
				if (v != null)
					element.value = v;
			}
		} else {
			for (element in getElements()) {
				//populate from web params
				element.populate();
			}
		}
	}

	/**
	 * Generate a form from any object
	 * @param	obj
	 */
	public static function fromObject(obj:Dynamic) {
		var form = new Form('fromObj');
		for (f in Reflect.fields(obj)) {
			var val = Reflect.field(obj, f);
			if (val == "") val = null;
			form.addElement(new sugoi.form.elements.StringInput(f, f, val));
		}		
		return form;
	}

	public function clearData()
	{
		for (element in getElements()){
			element.value = null;
		}
	}

	/**
	 * Prints form open tag <form ...>
	 */
	public function getOpenTag():String
	{
		//if there is a file input in the form, make it multipart
		for ( e in elements) {
			if (Type.getClass(e) == sugoi.form.elements.FileUpload || Type.getClass(e) == sugoi.form.elements.ImageUpload){
				multipart = true;
				break;
			}
		}
		return '<form id="' + id + '" class="'+defaultClass+'" name="' + name + '" method="' + method +'" action="' + action +'" ' + (multipart?'enctype="multipart/form-data"':'') + ' >';
	}

	/**
	 * Prints form close tag ...</form>
	 */
	public function getCloseTag():String
	{
		var s = new StringBuf();
		s.add('<div style="clear:both; height:0px;">&nbsp;</div>');
		s.add('<input type="hidden" name="' + name + '_formSubmitted" value="true" /></form>');
		return s.toString();
	}

	public function isValid():Bool
	{
		if (!isSubmitted()) return false;

		populate();

		var valid = true;

		for (element in getElements()){
			//trace(element.name+" -> "+element.value+" : "+element.isValid()+"<br>");
			element.filter();
			if (!element.isValid()) valid = false;
		}
		if (extraErrors.length > 0) valid = false;
		return valid;
	}

	public function checkToken() {
		return isValid();
	}

	public function addError(error:String)
	{
		extraErrors.add(error);
	}

	public function getErrorsList():List<String>
	{
		isValid();

		var errors:List<String> = new List();

		for(e in extraErrors)
			errors.add(e);

		for (element in getElements())
			for (error in element.getErrors())
				errors.add(error);

		return errors;
	}

	public function getElements():Array<FormElement<Dynamic>>
	{
		return elements;
	}

	public function isSubmitted():Bool
	{
		//if (multipart){
			//var req = sugoi.tools.Utils.getMultipart(1024 * 1024 * 12);
			//for ( r in req.keys() ) App.current.params.set(r, req.get(r));
		//}

		return App.current.params.get(name + "_formSubmitted") == "true";
	}

	public function getSubmittedValue():String
	{
		return App.current.params.get(name + "_formSubmitted");
	}

	public function getErrors():String
	{
		if (!isSubmitted())
			return "";

		var s:StringBuf = new StringBuf();
		var errors = getErrorsList();

		if (errors.length > 0)
		{
			if (USE_TWITTER_BOOTSTRAP) s.add('<div class="alert alert-danger">');
			s.add("<ul class=\"formErrors\" >");
			for (error in errors)
			{
				s.add("<li>"+error+"</li>");
			}
			s.add("</ul>");
			if (USE_TWITTER_BOOTSTRAP) s.add('</div>');
		}
		return s.toString();
	}

	/**
	 * Render form's HTML
	 */
	public function render()
	{

		var s:StringBuf = new StringBuf();
		s.add(getOpenTag());

		//errors
		if (isSubmitted())
			s.add(getErrors());

		for (element in getElements())
			if (element != submitButton && element.internal == false)
				s.add("\t"+element.getFullRow()+"\n");

		//submit button
		if (submitButton != null) {
			submitButton.parentForm = this;
		}else if(autoGenSubmitButton){
			submitButton = new Submit('submit', submitButtonLabel != null ? submitButtonLabel : 'OK');
			submitButton.parentForm = this;
		}
		if(submitButton!=null) s.add(submitButton.getFullRow());

		s.add(getCloseTag());

		return s.toString();
	}

	public dynamic function toString():String {
		return this.render();
	}
}
