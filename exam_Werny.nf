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





workflow {

download_reference_ch = download_reference()
download_collegue_fasta_ch = download_collegue_fasta()
combine_fasta(download_reference_ch,download_collegue_fasta_ch)


}