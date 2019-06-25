#!/usr/bin/env python
# ------------------------------------------------------------------ #
# This is a script to create a DCM Matlab code from a quasi-verbal 
# description of a model. 
#
# --- Author ------------------------------------------------------- #
#
#  Andrea Stocco,
#  Institute for Learning and Brain Sciences
#  and Department of Psychology
#  University of Washington
#  stocco@uw.edu
#
# --- History ------------------------------------------------------ #
#
# 2017-11-14 : * Added support for TE values
#              * Added support for loading model files from different 
#                folders
#
# 2015-11-08 : * Made sure inputs are not centered (in DCM10). Also,
#            : * fixed a bug on the doc string.
#
# 2012-09-20 : * Added documentation string
#
# 2012-08-12 : * First working version.
#
# 2012-08-01 : * File created.
# ------------------------------------------------------------------ #

HLP_MSG="""
Usage
-----
  $ dcm-generate-models.py <model_file> <dcm_dir> <subj1> <subj2> ... <subjN>

Where:
   
  <model_file> is the file containing the model description (see
    below)
  <dcm_dir> is the name of the folder where the single-subject  
    SPM.mat file is located (and where the DCM model will be 
    saved)
  <subjN> is the name of the folder corresponding to each subject.

Model Description
-----------------
The model description file is a text file that describes a DCM model
in a format that is transparent to the user.  A model file contains
a series of statements (one statement per line)  that describe the 
model's connectivity, as well as user comments. 

COMMENTS are introduced by the sharp sign '#', and behave very much
like shell comments: Everything between the sharp sign and the end 
of the line is ignored by the script.

A MODEL DESCRIPTION file begins with three statements:

  te: <TE value>
  vois: <region1> <region2> ... <regionN>
  inputs: <input1> <input2> ... <inputN>

Where <TE value> is the scanner's Echo Time (in secs; default is 
0.021), <regionX> names an existing VOI, and <inputX> gives a name to
the various conditions that are present in the single-subject SPM.mat 
file (i.e., the task model).

Note that the inputs must name the conditions in the order in which 
they appear. Furthermore, you need to specify ALL the condition names
UP TO the last one you intend to use, without skipping any condition
in-between. That is, if your SPM.mat file contains four conditions,
A, B, C, and D,  and you want to use only A and C, you still need to
include 'B' in-between (e.g., "inputs: A B C") even if you can omit 
'D'.  The reason is that the names are actually transformed into
indexes by the script, and skipping one name results in giving the  
following condition a wrong index.

Also, note that while the name of the VOIs need to be the SAME as the
name of the VOI files (except for the leading 'VOI_' suffix), the 
names of the conditions DO NOT need to be the same as the names in the
SPM.mat file. That is, you can call your conditions X, Y, and Z in the
SPM.mat file and refer to them as A, B, and C in the model description
file. However, they will still appear as X, Y, and Z in the final DCM,
because the DCM model will read the conditions names directly from the
SPM file (remember, the DCM specification uses indexes internally). 

After declaring inputs and VOIs, the remaining part of the model 
description is made of 'statements', i.e. descriptions of 
connectivity patterns. A DIRECT connectivity pattern is specified using
the arrow operator '->':

  <voi|input> -> <voi>

Note that the first term can be either a VOI or an input, but the 
second term can only be a VOI.  Also, note that the connectivity is
STRICTLY DIRECTIONAL, so that "A -> B" defines the connection FROM 
REGION A TO REGION B, and not viceversa. To specify bidirectional 
connections, you need to enter two separate statements, one for each
direction (e.g., "A -> B" and "B -> A").

This type of statement describes direction connection from VOIs to
VOIs and from inputs to VOIs. That is, they describe the 'A' and 'C'
matrices in the DCM file. To describe MODULATORY CONNECTIONS, you
can use the three-term-statement:

  <voi|input> -> <voi|input> -> <voi>

In the three-term statement, the first term can be either a VOI or an
input, and the second and third term describe another connection 
(either VOI-to-VOI or input-to-VOI) that exists in the model. This 
form is used to specify MODULATORY connections between a VOI or 
an input and an existing DIRECT connection.

Note that the connection between the second and the third term MUST
have already been specified when you use the three-term statement, 
i.e. in order to describe 'A -> B -> C', you need to have specified
'B -> C' first.

Usage
-----
  $ dcm-generate-models.py <model_file> <dcm_dir> <subj1> <subj2> ... <subjN>

Where:
   
  <model_file> is the file containing the model description (see
    below)
  <dcm_dir> is the name of the folder where the single-subject  
    SPM.mat file is located (and where the DCM model will be 
    saved)
  <subjN> is the name of the folder corresponding to each subject.
"""

import sys, copy, os, ntpath


def isDefinitionString(strng):
    """
A definition string is a string of the form '<inputs|vois|te> : <vals>'
    """
    if strng.count(':') is not 1: 
        return False
    else:
        tkns=strng.split(':')
        if len(tkns) == 2 and \
                len(tkns[0].split()) == 1 and \
                len(tkns[1].split()) >= 1:
            return True
        else:
            return False

def isConnectivityString(strng):
    if strng.count('->') not in [1,2]:
        return False
    else:
        tkns = strng.split('->')
        subs = [x.split() for x in tkns]
        ones = [x for x in subs if len(x)==1]
        
        if len(tkns) in [2,3] and len(subs) == len(ones):
            return True
        else:
            return False

class Definition(object):
    def __init__(self, cmnd, args):
        self.command   = cmnd.lower()
        self.arguments = args

def parseDefinition(ln):
    tkns = ln.split(':')
    cmnd = tkns[0].strip()
    args = tkns[1].split()
    return Definition(cmnd, args) 

class Connectivity(object):
    def __init__(self, frm, to, mod=None):
        self.to = to
        self.frm = frm
        self.mod = mod
        if mod == None:
            self.len = 2
        else:
            self.len = 3

        self.matrix = self.DetermineMatrix()

    def DetermineMatrix(self):
        if self.len == 2:
            if self.to.nature == "VOI" and self.frm.nature == "VOI":
                return 'a'
            elif self.to.nature == "VOI" and self.frm.nature == "Input":
                return 'c'
            else:
                raise Exception("Impossible connection from %s to %s" % (self.frm, self.to))
        else:
            if self.frm.nature == "VOI" and \
                    self.to.nature == "VOI" and \
                    self.mod.nature == "VOI":
                return 'd'
            elif self.frm.nature == "VOI" and\
                    self.to.nature == "VOI" and \
                    self.mod.nature == "Input":
                return 'b'
            else:
                raise Exception("Impossible connection from %s to %s modulated by %s" % (self.frm, self.to, self.mod))


    def Elements(self):
        if self.len == 2:
            return [self.frm, self.to]
        elif self.len == 3:
            return [self.frm, self.to, self.mod]
        else:
            raise Exception("Wrong number of elements for Connection: %s" % self.len)

    def __str__(self):
        if self.len == 3:
            return "DCM.%s(%d,%d,%d) = 1 %% %s -> %s -> %s" % \
                (self.matrix, self.to.index, self.frm.index, self.mod.index,
                 self.mod.name, self.frm.name, self.to.name)
        elif self.len == 2:
            return "DCM.%s(%d,%d) = 1 %% %s -> %s" % \
                (self.matrix, self.to.index, self.frm.index,
                 self.frm.name, self.to.name)


    def __repr__(self):
        return self.__str__()
        
class Element(object):
    def __init__(self, name, nature="VOI", vois=[], inputs=[]):
        self.name = name
        if nature in ["VOI", "Input"]:
            self.nature = nature
        else:
            raise Exception("Impossible nature for element: " % nature)
        if self.nature == "VOI":
            self.index = vois.index(self.name) + 1
        else:
            self.index = inputs.index(self.name) + 1

    def __eq__(self, other):
        if other != None and \
                self.nature == other.nature and \
                self.name == other.name and \
                self.index == other.index:
            return True
        else:
            return False

    def __hash__(self):
        return hash((self.name, self.nature, self.index))

    def __str__(self):
        return "%s<%s,%d>" % (self.name, self.nature, self.index)

    def __repr__(self):
        return self.__str__()

def parseElement(name, vois=[], inputs=[]):
    if name in vois and name not in inputs:
        #print "   element %s in VOIS" % name
        return Element(name, "VOI", vois=vois, inputs=inputs)
    elif name in inputs and name not in vois:
        #print "   element %s in INPUTS" % name
        return Element(name, "Input", vois=vois, inputs=inputs)
    elif name in inputs and name in vois:
        raise Exception("Ambiguous element: %s" % name)
    else:
        raise Exception("Cannot assign element: %s" % name)

def parseConnectivity(ln, vois=[], inputs=[]):
    tkns = ln.split('->')
    tkns = [x.strip() for x in tkns]
    elms = [parseElement(x, vois=vois, inputs=inputs) for x in tkns]
    
    if len(elms) == 2:
        return Connectivity(frm=elms[0], to=elms[1])
    elif len(elms) == 3:
        return Connectivity(mod=elms[0], frm=elms[1], to=elms[2])
    else:
        raise Exception("Too many elements for connectivity: " % elms)

class Model(object):
    def __init__(self, vois, inputs, te, connections, name="Model1", participant="", dcmFolder="DCM"):
        self.vois = vois
        self.inputs = inputs
        self.te = te
        self.connections = connections
        self.name = name
        self.participant = participant
        self.dcmFolder = dcmFolder

    def InputsUsed(self):
        """
        Analyzes the connections to return a list of all the inputs
        that are actually used in the model
        """
        U = []
        for c in self.connections:
            U += c.Elements()

        U = [x for x in U if x.nature == "Input"]
        #U.sort(key=lambda x: x.index)
        #U = [x.name for x in U]
        return(sorted(list(set(U)), key=lambda x: x.index))


    def IsNonlinear(self):
        if len([x for x in self.connections if x.matrix == 'd']):
            return True
        else:
            return False

    def Check(self):
        """
        Should check for obvious errors
        """
        # Once a model is loaded, some things
        # need to be recalculated, e.g., the indexes
        # of the inputs that are really used.
        U = []   # Inputs
        N = []   # Names
        for c in self.connections:
            U += c.Elements()

        U = [x for x in U if x.nature == "Input"]
        N = [x.name for x in self.InputsUsed()]
        for u in U:
            u.index = N.index(u.name)+1


def parse_file(fileName):
    """
Parses a file in the Model Definition Format and transforms it into
an abstract representation of the model.
    """

    name = ntpath.basename(fileName)
    if '.' in name:
        name = name[0:name.rindex('.')]
    
    V = [] # VOIs
    I = [] # Inputs
    C = [] # Connectivity
    TE = 0.021

    f = open(fileName, 'r')
    for line in f.readlines():
        line=line.strip()
 
        if '#' in line:
            # Remove comments from line. Comments
            # Start with '#' (like in C and Python).
            line=line[0:line.find('#')]

        if len(line) > 0:
            #print "Parsing: %s" % line

            if isDefinitionString(line):
                # A definition string is a line of the form
                # <inputs|vois> : <list>
                # print("Found dfntn: %s" % line, file=sys.stderr) 
                dfnt = parseDefinition(line)
                if dfnt.command == "vois":
                    V = dfnt.arguments
                    #print "VOIS", V

                elif dfnt.command == "inputs":
                    I = dfnt.arguments
                    #print "INPUTS", I

                elif dfnt.command == "te":
                    TE = float(dfnt.arguments[0])
                    #print("New TE is: %s" % TE, file=sys.stderr)

                else:
                    raise Exception("Unknown definition parameter: %s" % dfnt.command)

            elif isConnectivityString(line):
                # A connectivity definition is a string in any of these 
                # four possible forms:
                #
                #    (a) V1 -> V2
                #    (b) V1 -> V2 -> V3
                #    (c) I1 -> V1
                #    (d) I1 -> V1 -> V2
                #
                c = parseConnectivity(line, vois=V, inputs=I)
                C.append(c)
                
            else:
                # If the string is neither a definition nor a 
                # connectivity string, we have an uninterpretable 
                # command.
                raise Exception("Uninterpretable command: " % line)
                
            #print(line, isDefinitionString(line), isConnectivityString(line))
    #print C
    return Model(vois=V, inputs=I, te=TE, connections=C, name=name)

def model_to_matlab(model):
    """
Transforms an internal representation of a model into Matlab code
that can be used in an SPM script.
    """
    w = model.base
    p = model.participant
    f = model.dcmFolder

    # Starts printing code on STOUT
    print("\n% " + "-" * 66 +" %")
    print("%% DCM Model (%s) for Subject %s" % (model.name, model.participant))
    print("% " + "-" * 66 +" %\n")
    print("clear DCM;")
    print("load(fullfile('%s', '%s', '%s', 'SPM.mat'));" %
          (w, p, f))

    # Loads the VOIs
    print("\n% --- The VOIs " + '-' * 53 + " %")
    for i in range(len(model.vois)):
        print("load(fullfile('%s', '%s', '%s', 'VOI_%s_1.mat'), 'xY');" %
              (w, p, f, model.vois[i]))
        print("DCM.xY(%d) = xY;\n" % (i+1))
    
    # Basic initialization in Matlab

    print("DCM.n = length(DCM.xY); % Num of regions")
    print("DCM.v = length(DCM.xY(1).u); % Num of time points")
    print("DCM.Y.dt  = SPM.xY.RT;")
    print("DCM.Y.X0  = DCM.xY(1).X0;")
    print("for i = 1:DCM.n")
    print("    DCM.Y.y(:,i)  = DCM.xY(i).u;")
    print("    DCM.Y.name{i} = DCM.xY(i).name;")
    print("end\n")

    print("DCM.Y.Q    = spm_Ce(ones(1,DCM.n)*DCM.v);")
    print("DCM.U.dt   = SPM.Sess.U(1).dt;")

    # Now, calculate which inputs are used:

    U = [x.name for x in m.InputsUsed()]
    U = [m.inputs.index(x)+1 for x in U]
    U.sort()

    if len(U) == 1:
        print("DCM.U.name = [SPM.Sess.U(%d).name];" % U[0])
    elif len(U) > 1:
        print("DCM.U.name = [SPM.Sess.U(%d).name ..." % U[0])
        for j in U[1:-1]:
            print("              SPM.Sess.U(%d).name ..." % j)
        print("              SPM.Sess.U(%d).name];" % U[-1])
    else:
        raise Exception("Fatal Error: Not enough inputs in model %s" % model.name)

    # The Inputs 

    print("\n% --- The Inputs " + '-' * 51 + " %\n")

    # The time series for each input seem to contain 32 time points more than
    # needed (possibly one TR in 16-bin of microtime???). At any rate, it needs
    # to be accounted for in the Matlab code.

    if len(U) == 1:
        print("DCM.U.u    = [SPM.Sess.U(%d).u(33:end,1)];" % U[0])
    elif len(U) > 1:
        print("DCM.U.u    = [SPM.Sess.U(%d).u(33:end,1) ..." % U[0])
        for j in U[1:-1]:
            print("              SPM.Sess.U(%d).u(33:end,1) ... " % j)
        print("              SPM.Sess.U(%d).u(33:end,1)];" % U[-1])
    else:
        raise Exception("Fatal Error: Not enough inputs in model %s" % model.name)

    # Set delays and TE
    print("\n% Set delays and TE (TE should be gotten from SPM?)\n")
    print("DCM.delays = repmat(SPM.xY.RT,%d,1);" % len(model.vois))
    print("DCM.TE     = %.3f;" % model.te)

    # Set other options
    if model.IsNonlinear():
        print("DCM.options.nonlinear  = 1;")
    else:
        print("DCM.options.nonlinear  = 0;")
        
    print("DCM.options.two_state  = 0;")
    print("DCM.options.stochastic = 0;")
    print("DCM.options.centre = 0;")
    print("DCM.options.nograph    = 1;")

    # The Matrices:
    print("\n% --- The Matrices " + '-' * 49 + " %")
 
    # Matrix A
    print("\nDCM.a = eye(%d,%d);" % (len(model.vois), len(model.vois)))
    A = copy.copy(model.connections)
    A = [x for x in A if x.matrix == 'a']
    for a in A:
        print(a)
    
    # Matrix B
    print("\nDCM.b = zeros(%d,%d,%d);" % (len(model.vois), len(model.vois), len(model.InputsUsed())))
    B = copy.copy(model.connections)
    B = [x for x in B if x.matrix == 'b']
    for b in B:
        print(b)

    # Matrix C
    print("\nDCM.c = zeros(%d,%d);" % (len(model.vois), len(model.InputsUsed())))
    C = copy.copy(model.connections)
    C = [x for x in C if x.matrix == 'c']
    for c in C:
        print(c)

    # Matrix D
    print("\nDCM.d = zeros(%d,%d,%d);" % (len(model.vois), len(model.vois), len(model.vois)))
    D = copy.copy(model.connections)
    D = [x for x in D if x.matrix == 'd']
    for d in D:
        print(d)

    # Saving and Estimating
    print("\n% --- Saving and estimating " + '-' * 40 + " %\n")
    print("save(fullfile('%s', '%s', '%s', 'DCM_%s.mat'));" %
          (w, p, f, model.name))
    print("disp('Estimating model %s for subject %s');" % (model.name, p))
    print("spm_dcm_estimate(fullfile('%s', '%s', '%s', 'DCM_%s.mat'));" %
          (w, p, f, model.name))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(HLP_MSG)
    else:
        m=parse_file(sys.argv[1])
        m.Check()
        m.base = os.getcwd()
        m.dcmFolder = sys.argv[2]
        for subj in sys.argv[3:-1]:
            m.participant=subj
            model_to_matlab(m)
            print("\n")
        # The last one is ran aside to prevent the trailing "\n"
        m.participant=sys.argv[-1]
        model_to_matlab(m)
