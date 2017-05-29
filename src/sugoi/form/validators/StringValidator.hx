/*
 * Copyright (c) 2008, TouchMyPixel & contributors
 * Original author : Tony Polinelli <tonyp@touchmypixel.com>
 * Contributers: Tarwin Stroh-Spijer
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE TOUCH MY PIXEL & CONTRIBUTERS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE TOUCH MY PIXEL & CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */


package sugoi.form.validators;
import EReg;
using StringTools;

class StringValidator extends Validator<String>
{
	public var minChars:Int;
	public var maxChars:Int;
	public var charList:String;
	public var mode:StringValidatorMode;

	public var regex:EReg;
	public var regexError:String;

	public var errorMinChars:String;
	public var errorMaxChars:String;
	public var errorDenyChars:String;
	public var errorAllowChars:String;

	public function new(?minChars:Int=0, ?maxChars:Int=999999, ?charList:String="", ?mode:StringValidatorMode, ?regex:EReg = null, ?regexError:String)
	{
		super();

		errorMinChars = "Doit contenir au moins %s caractères";
		errorMaxChars = "Doit contenir moins de %s caractères";
		errorDenyChars = "Doit convenir les caractères '%s'";
		errorAllowChars = "Doit contenir uniquement les caractères '%s'";

		this.minChars = minChars;
		this.maxChars = maxChars;
		this.charList = charList;
		this.mode = mode;
		if (this.mode == null) this.mode = StringValidatorMode.ALLOW;

		this.regex = regex;
		this.regexError = regexError != null ? regexError : "Doesn't match required input.";

		errors = new List();
	}

	override public function isValid(value:Dynamic):Bool
	{
		super.isValid(value);

		var valid = true;
		var s = Std.string(value);

		if (minChars != null && minChars > 0 && s.length < minChars)
		{
			valid = false;
			errors.add(errorMinChars.replace("%s", Std.string(minChars)));
		}

		if (maxChars != null && maxChars > 0 && s.length > maxChars)
		{
			valid = false;
			errors.add(errorMaxChars.replace("%s", Std.string(maxChars)));
		}

		if (charList.length > 0)
		{
			switch(mode)
			{
				case StringValidatorMode.ALLOW:
					for (i in 0...s.length)
					{
						var letter = s.charAt(i);
						if (charList.indexOf(letter) == -1)
						{
							valid = false;
						//	errors.add(StringTools2.printf(errorAllowChars, [StringTools2.toSentenceList(charList)]));
							errors.add(errorAllowChars.replace("%s", charList));
							break;
						}
					}
				case StringValidatorMode.DENY:
					for (i in 0...s.length)
					{
						var letter = s.charAt(i);
						if (charList.indexOf(letter) != -1)
						{
							valid = false;
							//errors.add(StringTools2.printf(errorDenyChars, [StringTools2.toSentenceList(charList)]));
							errors.add(errorDenyChars.replace("%s", charList));
							break;
						}
					}
			}
		}

		if (regex != null)
		{
			if (!regex.match(s))
			{
				valid = false;
				errors.add(regexError);
			}
		}

		return valid;
	}

}


enum StringValidatorMode
{
	ALLOW;
	DENY;
}
