package controllers;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import models.entities.Variant;
import play.mvc.Controller;
import play.mvc.Result;


public class RestController extends Controller {
	
	
	@SuppressWarnings("serial")
	final Map<String, List<String>> impact2consequence = new HashMap<String, List<String>>(){{
		put("HIGH", new ArrayList<String>(Arrays.asList("transcript_ablation", "transcript_amplification", "start_lost", "splice_acceptor_variant", "splice_donor_variant", "stop_gained", "frameshift_variant", "stop_lost")));
		put("MODERATE", new ArrayList<String>(Arrays.asList("regulatory_region_ablation", "protein_altering_variant", "missense_variant", "inframe_deletion", "inframe_insertion")));
		put("LOW", new ArrayList<String>(Arrays.asList("synonymous_variant", "splice_region_variant", "stop_retained_variant", "incomplete_terminal_codon_variant", "start_retained_variant")));
		put("MODIFIER", new ArrayList<String>(Arrays.asList("intergenic_variant", "feature_truncation", "regulatory_region_variant", "feature_elongation", "regulatory_region_amplification", "TF_binding_site_variant", "TFBS_amplification", "TFBS_ablation", "downstream_gene_variant", "upstream_gene_variant", "non_coding_transcript_variant", "NMD_transcript_variant", "intron_variant", "non_coding_transcript_exon_variant", "3_prime_UTR_variant", "5_prime_UTR_variant", "mature_miRNA_variant", "coding_sequence_variant")));
	}};

	final List<String> allConsequences = new ArrayList<String>(Arrays.asList("intergenic_variant", "feature_truncation", "regulatory_region_variant", "feature_elongation", "regulatory_region_amplification", "TF_binding_site_variant", "TFBS_amplification", "TFBS_ablation", "downstream_gene_variant", "upstream_gene_variant", "non_coding_transcript_variant", "NMD_transcript_variant", "intron_variant", "non_coding_transcript_exon_variant", "3_prime_UTR_variant", "5_prime_UTR_variant", "mature_miRNA_variant", "coding_sequence_variant", "synonymous_variant", "splice_region_variant", "stop_retained_variant", "incomplete_terminal_codon_variant", "start_retained_variant", "regulatory_region_ablation", "protein_altering_variant", "missense_variant", "inframe_deletion", "inframe_insertion", "transcript_ablation", "transcript_amplification", "start_lost", "splice_acceptor_variant", "splice_donor_variant", "stop_gained", "frameshift_variant", "stop_lost"));
	
	final Map<String, String> allStrains = new HashMap<String, String>()
	{{
		put("c57bl_6j","C57BL_6J");
		put("c57bl_6j_ref","C57BL_6J_REF");
		put("129p2_olahsd","X129P2_OlaHsd");
		put("129s1_svimj","X129S1_SvImJ");
		put("129s5svevbrd","X129S5SvEvBrd");
		put("akr_j","AKR_J");
		put("a_j","A_J");
		put("balb_cj","BALB_cJ");
		put("btbr","BTBR");
		put("bub_bnj","BUB_BnJ");
		put("c3h_heh","C3H_HeH");
		put("c3h_hej","C3H_HeJ");
		put("c57bl_10j","C57BL_10J");
		put("c57bl_6nj","C57BL_6NJ");
		put("c57br_cdj","C57BR_cdJ");
		put("c57l_j","C57L_J");
		put("c58_j","C58_J");
		put("cast_eij","CAST_EiJ");
		put("cba_j","CBA_J");
		put("dba_1j","DBA_1J");
		put("dba_2j","DBA_2J");
		put("fvb_nj","FVB_NJ");
		put("i_lnj","I_LnJ");
		put("kk_hij","KK_HiJ");
		put("lewes_eij","LEWES_EiJ");
		put("lp_j","LP_J");
		put("molf_eij","MOLF_EiJ");
		put("nod_shiltj","NOD_ShiLtJ");
		put("nzb_b1nj","NZB_B1NJ");
		put("nzo_hlltj","NZO_HlLtJ");
		put("nzw_lacj","NZW_LacJ");
		put("pwk_phj","PWK_PhJ");
		put("rf_j","RF_J");
		put("sea_gnj","SEA_GnJ");
		put("spret_eij","SPRET_EiJ");
		put("st_bj","ST_bJ");
		put("wsb_eij","WSB_EiJ");
		put("zalende_eij","ZALENDE_EiJ");
	}};
	
    
    public Result finemap(String region, List<String> consequence, List<String> impact, List<String> strain1, List<String> strain2, Integer thr1, Integer thr2) {
    	
    	
    	// Parse thr
    	if(thr1 == null || thr1 < 0 || thr1 > strain1.size() - 1) {
    		thr1 = 0;
    	}
    	if(thr2 == null || thr2 < 0 || thr2 > strain2.size() - 1) {
    		thr2 = 0;
    	}
    	
    	
    	// Parse strains
    	Set<String> strains1 = new HashSet<String>();
    	Set<String> strains2 = new HashSet<String>();
    	for(String s : strain1) {
    		
    		String c = s.toLowerCase().trim();
    		
    		if(allStrains.containsKey(c)) {
    			strains1.add(allStrains.get(c));
    		}
    	}
    	
    	for(String s : strain2) {
    		
    		String c = s.toLowerCase().trim();
    		
    		if(allStrains.containsKey(c)) {
    			strains2.add(allStrains.get(c));
    		}
    	}
    	
//    	if(strains1.isEmpty() || strains2.isEmpty()) {
//    		return ok("Error: Strains are not supported");
//    	}
    	
    	
    	// Parse consequences
    	Set<String> consequences = new HashSet<String>();
    	for(String s : consequence) {
    		
    		String c = s.toLowerCase().trim();
    		
    		if(allConsequences.contains(c)) {
    			consequences.add(c);
    		};
    	}
    	
    	
    	// Parse impacts
    	for(String s : impact) {
    		
    		String c = s.toUpperCase().trim();
    		
    		if(impact2consequence.containsKey(c)) {
    			consequences.addAll(impact2consequence.get(c));
    		};
    	}
		
    	
    	// Parse region
		if(region.matches("^(chr)?([1-9]|1[0-9])$|^(chr)?([1-9]|1[0-9]):[0-9]+-[0-9]+$")) {

			
			final Pattern p1 = Pattern.compile("^(chr)?([1-9]|1[0-9])$");		
			Matcher m1 = p1.matcher(region);
			
			final Pattern p2 = Pattern.compile("^(chr)?([1-9]|1[0-9]):([0-9]+)-([0-9]+)$");		
			Matcher m2 = p2.matcher(region);
			
			int chr = 0;
			Integer start = null;
			Integer end = null;
			if(m1.find()) {
				chr = Integer.parseInt(m1.group(2));
			}
			else if(m2.find()) {
				chr = Integer.parseInt(m2.group(2));
				start = Integer.parseInt(m2.group(3));
				end = Integer.parseInt(m2.group(4));
			}

			
			// DB query
			List<Variant> res = Variant.finemap(chr, start, end, new ArrayList<String>(consequences), new ArrayList<String>(strains1), new ArrayList<String>(strains2), thr1, thr2);
			
			
			// Create result string
			StringBuilder sb = new StringBuilder();
			sb.append("#Alleles of strain C57BL_6J represent the reference (ref) alleles\n");
			sb.append("#reference_version=GRCm38\n");
			sb.append(String.join("\t", new ArrayList<String>(Arrays.asList("chr", "pos", "rsid", "ref", "alt", "most_severe_consequence", "consequences", "C57BL_6J", "129P2_OlaHsd", "129S1_SvImJ", "129S5SvEvBrd", "AKR_J", "A_J", "BALB_cJ", "BTBR", "BUB_BnJ", "C3H_HeH", "C3H_HeJ", "C57BL_10J", "C57BL_6NJ", "C57BR_cdJ", "C57L_J", "C58_J", "CAST_EiJ", "CBA_J", "DBA_1J", "DBA_2J", "FVB_NJ", "I_LnJ", "KK_HiJ", "LEWES_EiJ", "LP_J", "MOLF_EiJ", "NOD_ShiLtJ", "NZB_B1NJ", "NZO_HlLtJ", "NZW_LacJ", "PWK_PhJ", "RF_J", "SEA_GnJ", "SPRET_EiJ", "ST_bJ", "WSB_EiJ", "ZALENDE_EiJ"))) + "\n");
			for(Variant v : res) {
				sb.append(String.join("\t", new ArrayList<String>(Arrays.asList(v.chr, v.pos, v.rsid, v.ref, v.alt, v.mostSevereConsequence, v.consequenceTypes, v.C57BL_6J, v.X129P2_OlaHsd, v.X129S1_SvImJ, v.X129S5SvEvBrd, v.AKR_J, v.A_J, v.BALB_cJ, v.BTBR, v.BUB_BnJ, v.C3H_HeH, v.C3H_HeJ, v.C57BL_10J, v.C57BL_6NJ, v.C57BR_cdJ, v.C57L_J, v.C58_J, v.CAST_EiJ, v.CBA_J, v.DBA_1J, v.DBA_2J, v.FVB_NJ, v.I_LnJ, v.KK_HiJ, v.LEWES_EiJ, v.LP_J, v.MOLF_EiJ, v.NOD_ShiLtJ, v.NZB_B1NJ, v.NZO_HlLtJ, v.NZW_LacJ, v.PWK_PhJ, v.RF_J, v.SEA_GnJ, v.SPRET_EiJ, v.ST_bJ, v.WSB_EiJ, v.ZALENDE_EiJ))) + "\n");
			}
			
			
			return ok(sb.toString());
		}
		else {
			return ok("Error: Couldn't parse region");
		}
    }
}

