nextflow.enable.dsl = 2

params.temp = "${projectDir}/downloads" 
params.out = "${projectDir}/output"
params.accession = "M21012" //Hepatitis reference genome



// download the hepatitis reference fasta-file
process download_reference {
    //publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp
    
    output:
        path "${params.accession}.fasta"

    script:        
        """
        wget "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${params.accession}&rettype=fasta&retmode=text" -O "${params.accession}.fasta"
        """
}


//download one fasta file from collegue
process download_collegue_fasta {
    //publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp

    output:
      path "collegue_sequences_fasta"

    script:     
        """
        wget https://gitlab.com/dabrowskiw/cq-examples/-/raw/master/data/hepatitis_combined.fasta?inline=false -O "collegue_sequences_fasta"
        """
}

//combination of reference genome and sequences from collegue (necessary for upcoming alignment process)
process combine_fasta {
    //publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp

    input:
      path input1
      path input2

    output:
      path "combined_fasta"

    script:    
        """
        cat ${input1} ${input2} > "combined_fasta"
        """
}

//alignment process
process mafft {
    //publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp
    container "https://depot.galaxyproject.org/singularity/mafft%3A7.525--h031d066_1"

    input:
        path fastafile
      
    output:
      path "hepatitis_alignment.fasta"
    script:    
        """
        mafft --auto ${fastafile} > "hepatitis_alignment.fasta"
        """
}

//cleanup and report process
process trimal {
    publishDir params.out, mode: 'copy', overwrite: true
    storeDir params.temp
    container "https://depot.galaxyproject.org/singularity/trimal%3A1.5.0--h9948957_2"

    input:
        path fastafile
      
    output:
      path "hepatitis_cleaned_up_alignment.fasta"
      path "hepatitis_report.html"

    script:      
        """
        trimal -in ${fastafile} -out "hepatitis_cleaned_up_alignment.fasta" -htmlout "hepatitis_report.html" -automated1
        """
}



workflow {

download_reference_ch = download_reference()
download_collegue_fasta_ch = download_collegue_fasta()

combine_fasta(download_reference_ch,download_collegue_fasta_ch) | mafft | trimal


}