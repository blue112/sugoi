package sugoi.form.elements;

import sugoi.form.validators.*;

class PasswordInput extends StringInput
{
    public function new(name:String, label:String, ?value:String, ?required = false, ?validators:Array<Validator<String>>, ?attributes = "")
    {
        super(name, label, value, required, validators, attributes);
        this.password = true;
    }
}
