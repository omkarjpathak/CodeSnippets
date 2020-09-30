#!/usr/bin/env python3
""" Module for defining and working with a tartan run """

import datetime
import sys
import os
import glob

from pcheck import utils

class TartanRun:
    """ TartanRun class """
    def __init__(self, raptr_records, item_type, tartan_root):
        """ Initialization method """
        if item_type not in ["bam_pair", "bam", "loadable"]:
            sys.exit("ERROR: TartanRun can only have item types of bam_pair, "
                     "bam, or loadable.")

        self.__raptr_records = raptr_records
        self.__item_type = item_type
        self.__tartan_root = tartan_root
        self.__bad = False
        self.__project_group = None

        self.__status = None
        self.__steps = None

    @property
    def project_group(self):
        return self.__project_group

    @project_group.setter
    def project_group(self, project_group):
        self.__project_group = project_group

    @property
    def tartan_root(self):
        """ Tartan root directory """
        return self.__tartan_root

    @property
    def anls_run_name(self):
        """ Return the anls_run_name as a string """
        run_names = list(set([record[0] for record in self.__raptr_records]))
        assert len(run_names) == 1
        return run_names[0]

    @property
    def anls_run_type(self):
        """ Return the anls_run_type as a string """
        run_types = list(set([record[1] for record in self.__raptr_records]))
        assert len(run_types) == 1
        return run_types[0]

    @property
    def target(self):
        """ Return the target as a string """
        targets = []
        if self.__item_type in ["bam", "loadable"]:
            targets = list(set([record[4] for record in self.__raptr_records]))
        else:
            targets = list(set([record[7] for record in self.__raptr_records]))
        if len(targets) != 1:
            self.__bad = True
        return targets[0]

    @property
    def project(self):
        """ Return the project/subproject as a string """
        projects = list(set([record[2] for record in self.__raptr_records]))
        subprojects = list(set([record[3] for record in self.__raptr_records]))
        if len(projects) != 1 or len(subprojects) != 1:
            self.__bad = True
        return projects[0] + "/" + subprojects[0]

    @property
    def samples(self):
        """ Return the samples in a tartan_run as a list """
        if self.__item_type == "bam_pair":
            sample_index = 6
        elif self.__item_type == "bam" or self.__item_type == "loadable":
            sample_index = 5

        samples = list(set([record[sample_index] for record in self.__raptr_records]))
        return samples

    @property
    def rundir(self):
        """ Get the run directory of the tartan run """
        return "/".join([self.tartan_root, "runs", self.anls_run_type,
                         self.anls_run_name])
    @property
    def status(self):
        """ Return the status here (Running, Not Running, Failure, ?) """
        if self.__status:
            return self.__status
        workspace = self.rundir + "/workspace"
        progress_pipeline = workspace + "/progress-pipeline.txt"

        # If there is a workspace.zip file, return Zipped
        if os.path.isfile(self.rundir + "/workspace.zip"):
            self.__status = "Zipped"
            return self.__status

        # If it is reaped, return 'Reaped'
        if os.path.islink(workspace) and not os.path.exists(workspace):
            self.__status = utils.make_red("Reaped")
            return self.__status
        
        # Check status of 'progress_pipeline' style pipeline
        if os.path.isfile(progress_pipeline):
            if utils.pp_failed(progress_pipeline):
                self.__status = utils.make_red("FAILURE")
            else:
                self.__status = utils.lsf_pipeline_status(self.anls_run_name)
            return self.__status

        # Check status of 'phoenix' style pipeline
        if glob.glob(workspace + "/STEP*"):
            if utils.phoenix_failed(workspace):
                self.__status = utils.make_red("FAILURE")
            else:
                self.__status = utils.lsf_pipeline_status(self.anls_run_name)
            return self.__status

        # Check status of snv-indel-post pipeline
        if self.anls_run_type == "snv-indel-post-manual":
            self.__status = utils.status_from_sip(workspace, self.anls_run_name)
            return self.__status

        # Return unknown
        self.__status = utils.lsf_pipeline_status(self.anls_run_name)
        return self.__status

    @property
    def steps(self):
        """ Return the current_step / max_step of this pipeline """
        if self.__steps:
            return self.__steps
        if "Reaped" in self.__status:
            self.__steps = ("?", "?")
            return self.steps
        workspace = self.rundir + "/workspace"
        if self.status in ["Zipped", "Reaped"]:
            return ("?", "?")
        max_steps = "%i"%(utils.get_max_steps(workspace))
        cur_step = "%i"%(utils.get_cur_step(workspace))
        self.__steps = (cur_step, max_steps)
        return self.steps

    @property
    def datestr(self):
        """ Return the begin date as a string """
        dates = list(set([record[-1] for record in self.__raptr_records]))
        if len(dates) != 1:
            self.__bad = True
        return datetime.datetime.strftime(dates[0], "%Y-%m-%d")

    def report(self, wide=False, print_group=False, print_all_samples=False):
        """ Report this tartan run for pcheck to print to the screen """
        outstr = ""
        outstr += "%8s"%(self.anls_run_name)
        if wide:
            outstr += " %18s"%(self.anls_run_type)
            outstr += " %20s"%(self.project)
            outstr += " %15s"%(self.target)
            outstr += " %12s"%(self.datestr)
            if print_group:
                outstr += " %4s"%(self.project_group)
            outstr += " ... %s"%(self.status)
            outstr += " %2s/%2s"%(self.steps[0], self.steps[1])
            if print_all_samples:
                outstr += "\n\n"
                iterator = 0
                for sample in range(0, len(self.samples)):
                    iterator += 1
                    outstr += self.samples[sample] + "\t\t"
                    if iterator == 4:
                        outstr += "\n"
                        iterator = 0

        else:
            outstr += " %18s"%(self.anls_run_type[:16])
            outstr += " %20s"%(self.project[:18])
            outstr += " %15s"%(self.target[:14])
            outstr += " %12s"%(self.datestr)
            if print_group:
                outstr += " %4s"%(self.project_group)
            outstr += " ... %s"%(self.status)
            outstr += " %2s/%2s"%(self.steps[0], self.steps[1])
            if print_all_samples:
                outstr += "\n\n"
                iterator = 0
                for sample in range(0, len(self.samples)):
                    iterator += 1
                    outstr += self.samples[sample] + "\t\t"
                    if iterator == 4:
                        outstr += "\n"
                        iterator = 0

        return outstr

    def bad(self):
        """ Return whether or not this tartan run looks bad """
        return self.__bad

    def __str__(self):
        outstr = self.report()
        if self.__bad:
            return "%s ERROR"%(self.anls_run_name)
        return outstr

def split_raw_run_list(raw_list):
    """ Split the result of a raptr query into groups such that each group
        consists of only one anls_run.
    Args:
        raw_list (list): List of tuples - the result of a raptr query.
    Returns:
        raptr_records (dict): raptr_records[run_name] is a list of records.
    """
    raptr_records = {}
    for record in raw_list:
        anls_run_name = record[0]
        if anls_run_name not in raptr_records:
            raptr_records[anls_run_name] = [record]
        else:
            raptr_records[anls_run_name].append(record)

    return raptr_records


def get_tartan_runs(raw_loadable_list, raw_bam_list, raw_bam_pair_list,
                    tartan_root, raptr_conn):
    """ Get all tartan runs from the queries. """
    item_lists = {
        "loadable": raw_loadable_list,
        "bam": raw_bam_list,
        "bam_pair": raw_bam_pair_list
    }
    tartan_runs = {}
    for item_type in item_lists:
        raw_list = item_lists[item_type]
        raptr_record_dict = split_raw_run_list(raw_list)
        for anls_run_name in raptr_record_dict:
            raptr_records = raptr_record_dict[anls_run_name]

            tartan_run = TartanRun(raptr_records, item_type, tartan_root)
            _project = tartan_run.project.split('/')[0]
            _subproject = tartan_run.project.split('/')[1]
            tartan_run.project_group = \
                utils.get_project_group(raptr_conn, _project, _subproject)
            tartan_runs[anls_run_name] = tartan_run

    return tartan_runs
