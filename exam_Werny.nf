nextflow.enable.dsl = 2

params.temp = "${projectDir}/downloads" 
params.out = "${projectDir}/output"


params.accession = "M21012" //M21012 - Reference



// download one reference fasta-file
process download_reference {
    publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp
    
    output:
        path "${params.accession}.fasta"
            
    """
    wget "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${params.accession}&rettype=fasta&retmode=text" -O "${params.accession}.fasta"
    """
}


//download one fasta file from collegue
process download_collegue_fasta {
    publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp

    output:
      path "collegue_fasta"
            
    """
    wget https://gitlab.com/dabrowskiw/cq-examples/-/raw/master/data/hepatitis_combined.fasta?inline=false -O "collegue_fasta"
    """
}


process combine_fasta {
    publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp

    input:
      path input1
      path input2

    output:
      path "combined_fasta"
            
    """
    cat ${input1} ${input2} > "combined_fasta"
    """
}

process mafft {
    publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp

    container "https://depot.galaxyproject.org/singularity/mafft%3A7.525--h031d066_1"

    input:
        path fastafile
      
    output:
      path "alignment.fasta"
            
    """
    mafft --auto ${fastafile} > "alignment.fasta"
    """
}

process trimal {
    publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp

    container "https://depot.galaxyproject.org/singularity/trimal%3A1.5.0--h9948957_2"

    input:
        path fastafile
      
    output:
      path "cleaned_up_alignment.fasta"
      path "report.html"
            
    """
    trimal -in ${fastafile} -out "cleaned_up_alignment.fasta" -htmlout "report.html" -automated1
    """
}




workflow {

download_reference_ch = download_reference()
download_collegue_fasta_ch = download_collegue_fasta()
combine_fasta_ch = combine_fasta(download_reference_ch,download_collegue_fasta_ch)

mafft_ch = mafft(combine_fasta_ch)

trimal(mafft_ch)
}