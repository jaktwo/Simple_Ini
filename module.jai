//
// This INI file module is designed to be simple to use and understand. This means no subsections and no multiline
// values, just simple name-value pairs inside sections.
// 
// Quotation marks at the start and end of a value will be removed, and comment indicators hold precedence over quotation
// marks.
//
// A sequence of two or more whitespaces in a value will render any following characters into comments and they will
// therefore be ignored. This is by design to keep things easy to both parse and read.
//
// Values are always read as strings, the user has to provide the type when requesting values, and they could potentially
// be incorrectly interpreted.
//
// Comments should be preceded by whitespace or horizontal tabulations. Otherwise they will be interpeted as part of the
// value.
//
// ".ini"  files should be kept simple and for simple purposes. If you need multiline values, complex strings or
// subsections, you probably should be using some other format. Use this module to save simple data that you want users
// to have an easy time at modifying. I would use this to save things like audio volumes, screen size and keymap
// bindings in a 2D computer game :) - jak, 7 March 2025
//

Ini_File :: struct {
    table: Table(string, Table(string, string));
}

Parsing_Error :: enum s8 {
    OK                    ::  0;
    DUPLICATE_SECTION     :: -1;
    DUPLICATE_NAME        :: -2;
    INVALID_CHAR_SECTION  :: -3;
    INVALID_CHAR_NAME     :: -4;
    INCOMPLETE_SECTION    :: -5;
    INCOMPLETE_NAME       :: -6;
    ESCAPE_SEQUENCE_VALUE :: -7;
}

reset :: (file: *Ini_File) {
    table_reset(*file.table);
}

read_ini_file :: (path: string) -> file: Ini_File #must, error: Parsing_Error {
    file: Ini_File;
    
    ini_file_contents: string;

    error: Parsing_Error = .OK;

    if file_exists(path) {
	ini_file_contents = read_entire_file(path);
    }

    parsing: Parsing_State = .NEW_ITEM;

    values_table: Table(string, string);

    section_builder: String_Builder;
    name_builder:    String_Builder;
    value_builder:   String_Builder;

    append(*section_builder, "global");

    for ini_file_contents {
	if parsing == {
	    case .NEW_ITEM;
	    if it == #char "[" {
		parsing = .SECTION;

		section := builder_to_string(*section_builder);

		if table_contains(*file.table, section) {
		    error = .DUPLICATE_SECTION;

		    reset(*file);
		    
		    break;
		}
		
		if values_table.count > 0 {
		    table_add(*file.table, section, values_table);

		    table_reset(*values_table);
		}
	    }

	    else if it == 13 || it == 10 { }

	    else if it == #char ";" || it == #char "#" then parsing = .COMMENT;

	    else if (it >= 65 && it <= 90) || (it >= 97 && it <= 122) || it == #char "_" {
		parsing = .NAME;

		append(*name_builder, it);
	    }

	    else if it_index == ini_file_contents.count - 1 {
		section := builder_to_string(*section_builder);

		if table_contains(*file.table, section) {
		    error = .DUPLICATE_SECTION;

		    reset(*file);
		    
		    break;
		}
		
		if values_table.count > 0 {
		    table_add(*file.table, section, values_table);

		    table_reset(*values_table);
		}
	    }

	    else {
		error = .INVALID_CHAR_NAME;

		reset(*file);

		break;
	    }

	    case .COMMENT;
	    if it == 10 || it == 13 then parsing = .NEW_ITEM;

	    case .SECTION;
	    if it == #char "]" then parsing = .NEW_ITEM;

	    else if (it >= 65 && it <= 90) || (it >= 97 && it <= 122) || it == #char "_" {
		append(*section_builder, it);
	    }

	    else {
		error = .INVALID_CHAR_SECTION;

		reset(*file);

		break;
	    }

	    case .NAME;
	    if (it >= 65 && it <= 90) || (it >= 97 && it <= 122) || it == #char "_" {		
		append(*name_builder, it);
	    }

	    else if it == #char "=" {
		parsing = .VALUE;
	    }

	    else {
		error = .INVALID_CHAR_NAME;

		reset(*file);

		break;
	    }

	    case .VALUE;
	    previous_char_was_whitespace := false;
	    
	    if it == #char " " {
		if previous_char_was_whitespace {
		    parsing = .COMMENT;

		    if value_builder.initialized {
			name := builder_to_string(*name_builder);

			if table_contains(*values_table, name) {
			    error = .DUPLICATE_NAME;

			    reset(*file);

			    break;
			}

			table_add(*values_table, name, builder_to_string(*value_builder));
		    }
		}

		else previous_char_was_whitespace = true;
	    }

	    else if it == 9 {
		parsing = .COMMENT;

		if value_builder.initialized {
		    name := builder_to_string(*name_builder);

		    if table_contains(*values_table, name) {
			error = .DUPLICATE_NAME;

			reset(*file);

			break;
		    }

		    table_add(*values_table, name, builder_to_string(*value_builder));
		}
	    }

	    else if previous_char_was_whitespace && (it == #char ";" || it == #char "#") {
		parsing = .COMMENT;

		if value_builder.initialized {
		    name := builder_to_string(*name_builder);

		    if table_contains(*values_table, name) {
			error = .DUPLICATE_NAME;

			reset(*file);

			break;
		    }

		    table_add(*values_table, name, builder_to_string(*value_builder));
		}
	    }

	    else if it == 10 || it == 13 {
		parsing = .NEW_ITEM;

		if value_builder.initialized {
		    name := builder_to_string(*name_builder);

		    if table_contains(*values_table, name) {
			error = .DUPLICATE_NAME;

			reset(*file);

			break;
		    }

		    table_add(*values_table, name, builder_to_string(*value_builder));
		}
	    }

	    else {
		if previous_char_was_whitespace then append(*value_builder, " ");

		append(*value_builder, it);
	    }
	}

	if it_index == ini_file_contents.count - 1 {
	    if parsing == {
		case .NEW_ITEM;
		section := builder_to_string(*section_builder);
		
		if table_contains(*file.table, section) {
		    error = .DUPLICATE_SECTION;

		    reset(*file);

		    break;
		}
		
		case .SECTION;
		error = .INCOMPLETE_SECTION;

		reset(*file);
		
		break;

		case .NAME;
		error = .INCOMPLETE_NAME;

		reset(*file);
		
		break;

		case .VALUE;
		section := builder_to_string(*section_builder);
		
		if table_contains(*file.table, section) {
		    error = .DUPLICATE_SECTION;

		    reset(*file);

		    break;
		}

		name := builder_to_string(*name_builder);

		if table_contains(*values_table, name) {
		    error = .DUPLICATE_NAME;

		    reset(*file);

		    break;
		}

		table_add(*values_table, name, builder_to_string(*value_builder));

		table_add(*file.table, section, values_table);

		table_reset(*values_table);
	    }
	}
    }    

    return file, error;
}

main :: () {
    ini_file, error := read_ini_file("./tests/correct.ini");

    for ini_file.table {
	print("%\n", it);
    }

    if error == {
	case .OK;
	print("Went ok!\n");

	case .DUPLICATE_SECTION;
	print("Oops! Duplicate section!\n");

	case .DUPLICATE_NAME;
	print("Oops! Duplicate name!\n");

	case .INVALID_CHAR_SECTION;
	print("Oops! Invalid character while parsing section!\n");

	case .INVALID_CHAR_NAME;
	print("Oops! Invalid character while parsing name!\n");

	case .INCOMPLETE_SECTION;
	print("Oops! Found an incomplete section!\n");

	case .INCOMPLETE_NAME;
	print("Oops! Found an incomplete name!\n");

	case .ESCAPE_SEQUENCE_VALUE;
	print("Oops! Escape sequences in values are not allowed!\n");
    }
}

#scope_file

Parsing_State :: enum u8 {
    NEW_ITEM;
    COMMENT;
    SECTION;
    NAME;
    VALUE;
}

#import "Basic";
#import "File";
#import "File_Utilities";
#import "Hash_Table";
#import "String";
