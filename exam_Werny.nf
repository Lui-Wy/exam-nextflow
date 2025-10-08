nextflow.enable.dsl = 2

params.temp = "${projectDir}/downloads" 
params.out = "${projectDir}/output"
params.accession = "M21012" //Hepatitis reference genome

params.input = "${projectDir}/input" // alternative for storing the sequence files of your collegue on your harddrive


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
    publishDir params.input, mode: 'copy', overwrite: true //stores data locally in "input"-folder, if you have other sequences, put them here: "${projectDir}/input" 
    storeDir params.temp

    output:
      path "collegue_sequences.fasta"

    script:     
        """
        wget https://gitlab.com/dabrowskiw/cq-examples/-/raw/master/data/hepatitis_combined.fasta?inline=false -O "collegue_sequences.fasta"
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
      path "combined.fasta"

    script:    
        """
        cat ${input1} ${input2} > "combined.fasta"
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
      path "${params.accession}_alignment.fasta"
    script:    
        """
        mafft --auto ${fastafile} > "${params.accession}_alignment.fasta"
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
      path "${params.accession}_cleaned_up_alignment.fasta"
      path "${params.accession}_report.html"

    script:      
        """
        trimal -in ${fastafile} -out "${params.accession}_cleaned_up_alignment.fasta" -htmlout "${params.accession}_report.html" -automated1
        """
}



workflow {

download_reference_ch = download_reference()
download_collegue_fasta_ch = download_collegue_fasta()

combine_fasta(download_reference_ch,download_collegue_fasta_ch) | mafft | trimal


/*alternative with stored data

stored_collegue_fasta_ch = channel.fromPath("${params.input}/*.fasta") 
combine_fasta(download_reference_ch, stored_collegue_fasta_ch) | mafft | trimal

*/

}