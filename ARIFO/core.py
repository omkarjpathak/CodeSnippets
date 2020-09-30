#!/usr/bin/env python3
""" Core ARIFO functionality """

import sys
import os
from shutil import copyfile

from arifo import utils, gsf
from aux_utils import run_shell_command

def main():
    """ Main entry point """
    # Get the arguments
    args = utils.get_args(sys.argv)

    # Verify that the intake config path exists
    if not os.path.isfile(args.intake_config):
        sys.exit("Error: Intake config path DNE: '{}'"\
            .format(args.intake_config))

    # Read the file
    (intake_config_lines, intake_type) = utils.\
        read_and_verify_intake_config(args.intake_config, args.fq_dne_fail)

    # Try to infer the new intake config information
    if intake_type == "GSF":
        (new_ic_lines, success) = gsf.main(intake_config_lines)
    else:
        sys.exit("ERROR: Unknown data source")

    status = ""
    if success:
        status = "Success"
    else:
        sys.exit()

    # Write out the new intake config file to a tmp location
    fout = open(args.output_intake_config, 'w')
    for line in new_ic_lines:
        fout.write(line + "\n")
    fout.close()

    # Try to validate it
    (stdout, stderr, return_code) = \
        run_shell_command("validate_intake_config.pl %s"%(fout.name))

    if return_code != 0 or "Validation successful!" not in stdout:
        sys.exit(0)
    else:
        "INFO: Validation successful"

    # Email analysts
    if args.email_analysts:
        utils.email_analysts(new_ic_lines, args, status)
