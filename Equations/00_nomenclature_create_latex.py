import pandas as pd
import pdb


def write_math_symbols(file_addnon="", command="newcommand"):
    tex_file = "00_math_symbols%s.tex" % file_addnon

    # print tex_file
    with open(tex_file, "w") as f:
        f.write("%!TEX root = SPINE_model_equations.tex\n")

        for idx in df[(df["math_symbols"] == 1)].index:
            if df.loc[idx, "optional"] != "":
                f.write("\\{command}{{{latexcommand}}}[1][{optional}]{{{latex}}}\n".format(
                    command=command,
                    latexcommand=df.loc[idx, "latexcommand"],
                    optional=df.loc[idx, "optional"],
                    latex=df.loc[idx, "latex"]))
            else:
                f.write("\\{command}{{{latexcommand}}}{{{latex}}}\n".format(
                    command=command,
                    latexcommand=df.loc[idx, "latexcommand"],
                    latex=df.loc[idx, "latex"]))


REPLACE = True

COMMANDS = True
NOMENCLATURE = True
NOMENCLATURE_ADDON = False

df = pd.read_excel("00_nomenclature_definition.xlsx").sort_values(by="sort")
# df.loc[~pd.isnull(df["unit"]), "unit"] = df.loc[~pd.isnull(df["unit"]), "unit"].apply(lambda x: "[" + x + "]")
df.fillna("", inplace=True)
# print df

first_column = "p{\cola}"
second_column = "p{\colc}"
third_column = ">{\small\\raggedleft\\arraybackslash\\itshape}p{\colb}"
if COMMANDS:
    write_math_symbols()
    # write_math_symbols("1_det", "renewcommand")

if NOMENCLATURE:
    tex_file = "00_nomenclature.tex"
    if not REPLACE:
        tex_file = tex_file[:-4] + "_alt.tex"

    # print tex_file
    with open(tex_file, "w") as f:
        f.write("%!TEX root = SPINE_model_equations.tex\n")

        f.write("{0}\n% {1}\n{0}\n".format("%" * 75, "Nomenclature"))
        f.write("\\section*{Nomenclature}\n")
        # f.write("\\addcontentsline{toc}{chapter}{Nomenclature}\n\n")

        f.write("\\newcount\\totalcol\n")
        f.write("\\totalcol = 3\n")
        f.write("\\newdimen\\cola\n")
        f.write("\\cola = 6cm\n")
        f.write("\\newdimen\\colb\n")
        f.write("\\colb = 0cm\n")
        f.write("\\newdimen\\colc\n")
        f.write(
            "\\colc =\\dimexpr\\textwidth -\\tabcolsep *\\totalcol * 2 -\\arrayrulewidth * (1 +\\totalcol)-\\cola -\\colb\\relax\n")

        sections = {"1_SPINE": "SPNE model"
                    # "3_stoch": "Risk Aversion and Capacity Mechanisms"
                    }

        for s in sorted(sections.keys()):
            print s, sections[s]
            # f.write("{0}\n% {1}\n{0}\n".format("%" * 75, sections[s]))
            # f.write("\\pdfbookmark[section]{%s}{%s}\n" % (sections[s], s))
            # f.write("\\section*{%s}\label{nom:%s}\n" % (sections[s], s))

            f.write("{0}\n% {1}\n{0}\n".format("%" * 75, "Sets"))
            # f.write("\\pdfbookmark[subsection]{Sets}{Sets_%s}\n" % s)
            f.write("\\subsection*{Sets}\n")
            f.write("\\vspace{-1em}\n")
            f.write("\t\\begin{longtable}{%s %s %s}\n" % (first_column, second_column, third_column))
            for idx in df[(df["class"] == "Set") & (df[s] == 1)].index:
                f.write("\t\t${latexcommand:<15}$\t& {description:<60}\t& {unit:<15}\\\\\n".format(
                    latexcommand=df.loc[idx, "latexcommand"],
                    description=df.loc[idx, "description"],
                    unit=df.loc[idx, "unit"],
                ))
            f.write("\t\\end{longtable}\n\n")

            f.write("{0}\n% {1}\n{0}\n".format("%" * 75, "Parameters"))
            # f.write("\\pdfbookmark[subsection]{Parameters}{Parameters_%s}\n" % s)
            f.write("\\subsection*{Parameters}\n")
            f.write("\\vspace{-1em}\n")
            f.write("\t\\begin{longtable}{%s %s %s}\n" % (first_column, second_column, third_column))
            group = None
            for idx in df[(df["class"] == "Param") & (df[s] == 1)].index:
                group_new = df.loc[idx, "sort"].split("_")[1] # gives the string part after the first _

                if group is not None and group != group_new:
                    f.write("[0.5em]\n\n")
                else:
                    f.write("\n")

                f.write("\t\t${latexcommand:<15}$\t& {description:<60}\t& {unit:<15}\\\\".format(
                    latexcommand=df.loc[idx, "latexcommand"],
                    description=df.loc[idx, "description"],
                    unit=df.loc[idx, "unit"],
                ))
                group = group_new
            f.write("\n")
            f.write("\t\\end{longtable}\n\n")

            # Decision Variables
            f.write("{0}\n% {1}\n{0}\n".format("%" * 75, "Variables"))
            # f.write("\\pdfbookmark[subsection]{Decision Variables}{DecisionVariables_%s}\n" % s)
            f.write("\\subsection*{Decision Variables}\n")
            f.write("\\vspace{-1em}\n")
            f.write("\t\\begin{longtable}{%s %s %s}" % (first_column, second_column, third_column))
            group = None
            for idx in df[(df["class"] == "Var") & (df[s] == 1)].index:
                group_new = df.loc[idx, "sort"].split("_")[1]

                if group is not None and group != group_new:
                    f.write("[0.5em]\n\n")
                else:
                    f.write("\n")

                f.write("\t\t${latexcommand:<15}$\t& {description:<60}\t& {unit:<15}\\\\".format(
                    latexcommand=df.loc[idx, "latexcommand"],
                    description=df.loc[idx, "description"],
                    unit=df.loc[idx, "unit"],
                ))
                group = group_new

            f.write("\n")
            f.write("\t\\end{longtable}\n\n")

#            # Dual Variables
#            f.write("{0}\n% {1}\n{0}\n".format("%" * 75, "Dual variables"))
#            f.write("\\pdfbookmark[subsection]{Dual Variables}{DualVariables_%s}\n" % s)
#            f.write("\\subsection*{Dual Variables}\n")
#            f.write("\\vspace{-1em}\n")
#            f.write("\t\\begin{longtable}{%s %s %s}" % (first_column, second_column, third_column))
#            group = None
#            for idx in df[(df["class"] == "Dual") & (df[s] == 1)].index:
#                group_new = df.loc[idx, "sort"].split("_")[1]
#
#                if group is not None and group != group_new:
#                    f.write("[0.5em]\n\n")
#                else:
#                    f.write("\n")
#
#                f.write("\t\t${latexcommand:<15}$\t& {description:<60}\t& {unit:<15}\\\\".format(
#                    latexcommand=df.loc[idx, "latexcommand"],
#                    description=df.loc[idx, "description"],
#                    unit=df.loc[idx, "unit"],
#                ))
#                group = group_new
#
#            f.write("\n")
#            f.write("\t\\end{longtable}\n")
#
#            # Auxiliaries
#            f.write("{0}\n% {1}\n{0}\n".format("%" * 75, "Auxiliaries"))
#            f.write("\\pdfbookmark[subsection]{Auxiliaries}{Auxiliaries_%s}\n" % s)
#            f.write("\\subsection*{Auxiliaries}\n")
#            f.write("\\vspace{-1em}\n")
#            f.write("\t\\begin{longtable}{%s %s %s}" % (first_column, second_column, third_column))
#            group = None
#            for idx in df[(df["class"] == "Aux") & (df[s] == 1) & (df["nomenclature"] == 1)].index:
#                group_new = df.loc[idx, "sort"].split("_")[1]
#
#                if group is not None and group != group_new:
#                    f.write("[0.5em]\n\n")
#                else:
#                    f.write("\n")
#
#                f.write("\t\t${latexcommand:<15}$\t& {description:<60}\t& {unit:<15}\\\\".format(
#                    latexcommand=df.loc[idx, "latexcommand"],
#                    description=df.loc[idx, "description"],
#                    unit=df.loc[idx, "unit"],
#                ))
#                group = group_new
#
#            f.write("\n")
#            f.write("\t\\end{longtable}\n")

if NOMENCLATURE_ADDON:
    tex_file = "../sections/A_nomenclature_additional.tex"
    if not REPLACE:
        tex_file = tex_file[:-4] + "_alt.tex"

    # print tex_file
    with open(tex_file, "w") as f:
        f.write("%!TEX root = ../2017_thesis_hoeschle.tex\n")

        f.write("{0}\n% {1}\n{0}\n".format("%" * 75, "Additional Nomenclature"))
        f.write("\\section*{Additional Nomenclature}\n")
        f.write("\\addcontentsline{toc}{section}{Additional Nomenclature}\n\n")

        f.write("\\newcount\\totalcol\n")
        f.write("\\totalcol = 3\n")
        f.write("\\newdimen\\cola\n")
        f.write("\\cola = 1.3cm\n")
        f.write("\\newdimen\\colb\n")
        f.write("\\colb = 1.6cm\n")
        f.write("\\newdimen\\colc\n")
        f.write(
            "\\colc =\\dimexpr\\textwidth -\\tabcolsep *\\totalcol * 2 -\\arrayrulewidth * (1 +\\totalcol)-\\cola -\\colb\\relax\n")
        f.write("\t\\begin{longtable}{%s %s %s}\n" % (first_column, second_column, third_column))
        for idx in df[(df["nomenclature_appendix"] == 1)].index:
            f.write("\t\t${latexcommand:<15}$\t& {description:<60}\t& {unit:<15}\\\\\n".format(
                latexcommand=df.loc[idx, "latexcommand"],
                description=df.loc[idx, "description"],
                unit=df.loc[idx, "unit"],
            ))
        f.write("\t\\end{longtable}\n\n")
