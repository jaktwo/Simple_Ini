// @FILE: module.jai
// @AUTHOR: jak2 <jak2@clover-work.shop>

Ini_File :: struct {
    path_with_filename: string;
    table: Table(string, Table(string, string));
}

// if the file does not exist, it is created and the value of existed indicates this
read_ini_file :: (path_to_file: string) -> ini_file: Ini_File #must, existed: bool, success: bool {
    ini_file: Ini_File;  

    existed := true;
    
    success := true;
    
    if !file_exists(path_to_file) {
	write_entire_file(path_to_file, "");

	existed = false;
    }

    ini_file_contents := read_entire_file(path_to_file);

    key_builder: String_Builder;

    value_builder: String_Builder;
    
    section_builder: String_Builder;
    append(*section_builder, "global");

    values_table: Table(string, string);

    parsing: Parsing_File = .NOTHING;
    
    for ini_file_contents {
	if it == #char " " then continue;
	
	if parsing == {
	    case .NOTHING;
	        if it == #char "\n" then parsing = .KEY;

	    case .KEY;
	        if it == {
		    case #char "[";
		        if values_table.count > 0 then table_add(
			    *ini_file.table,
			    builder_to_string(*section_builder, do_reset=false),
			    values_table
			);
		    
		        reset(*section_builder);
		    
		        parsing = .SECTION;

		        continue;
	    
	            case #char ";";
		        if key_builder.current_buffer.count > 0 {
			    parsing = .NOTHING;
			    continue;
                        }
		    
		        #through;

	            case #char "=";
		        if key_builder.current_buffer.count > 0 {
			    parsing = .VALUE;
			    continue;
			}

		        #through;

                    case #char "\n";
		        if key_builder.current_buffer.count > 0 {
		            print("Error while parsing key: ");
			    print("unexpected escape sequence before value assignment ");
                            print("(key name found:\"%\").\n", builder_to_string(*key_builder));
		    
		            break;
		        }
		}

	        append(*key_builder, it);

	    case .SECTION;
	        if it == {
		    case #char "]";
		        parsing = .KEY;
    
		        continue;

	            case #char "\n";
		        print("Error while parsing section: ");
		        print("unexpected escape sequence before closing bracket ");
                        print("(section name found: \"%\").\n", builder_to_string(*section_builder));

		        break;
		}

	        append(*section_builder, it);

            case .VALUE;
	        if it == {
		    case #char ";";
		        #through;

	            case #char "#";
		        parsing = .NOTHING;
		        #through;

	            case #char "\n";
		        table_add(*values_table, builder_to_string(*key_builder), builder_to_string(*value_builder));
		    
		        reset(*key_builder);
		        reset(*value_builder);		    

		        parsing = .KEY;
		    
		        continue;   
	        }
	    
	        append(*value_builder, it);
	}
    }

    return ini_file, existed, success;
}

set_value :: (file: *Ini_File, name: string, value: $T) -> success: bool {

}

set_value_in_section :: (file: *Ini_File, name: string, value: $T) -> success: bool {

}

get_value_from_section_as :: (file: *Ini_File, key: string, section: string, $T: Type = int)
    -> is_valid: bool, value: T {

}

get_value_as :: (file: *Ini_File, key: string, $T: Type = int) -> is_valid: bool, value: T {
    
}

write_ini_file :: (file: *Ini_File, do_reset := false) {

}

write_ini_file :: (file: *Ini_File, new_path: string, do_reset := false) {

}

// testing
main :: () {
    ini_file: Ini_File = read_ini_file("./config.ini");
}

#scope_file

Parsing_File :: enum u8 {
    NOTHING;
    KEY;
    VALUE;
    SECTION;
}

#import "Basic";
#import "File";
#import "File_Utilities";
#import "Hash_Table";
