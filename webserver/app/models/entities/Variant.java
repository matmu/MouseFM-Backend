package models.entities;

import java.util.ArrayList;
import java.util.List;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Table;

import io.ebean.Ebean;
import io.ebean.EbeanServer;
import io.ebean.Model;
import io.ebean.Query;


@Entity
@Table(name="geno")
public class Variant extends Model {
	
	@Column(nullable=false, name="chr")
	public String chr;
	
	@Column(nullable=false, name="pos")
	public String pos;
	
	@Column(nullable=false, name="ref")
	public String ref;
	
	@Column(nullable=false, name="alt")
	public String alt;
	
	@Column(nullable=false, name="rsid")
	public String rsid;
	
	@Column(nullable=false, name="most_severe_consequence")
	public String mostSevereConsequence;
	
	@Column(nullable=false, name="consequences")
	public String consequenceTypes;
	
	
	@Column(nullable=false, name="C57BL_6J")
	public String C57BL_6J;
	
	@Column(nullable=false, name="129P2_OlaHsd")
	public String X129P2_OlaHsd;
	
	@Column(nullable=false, name="129S1_SvImJ")
	public String X129S1_SvImJ;
	
	@Column(nullable=false, name="129S5SvEvBrd")
	public String X129S5SvEvBrd;
	
	@Column(nullable=false, name="AKR_J")
	public String AKR_J;
	
	@Column(nullable=false, name="A_J")
	public String A_J;
	
	@Column(nullable=false, name="BALB_cJ")
	public String BALB_cJ;
	
	@Column(nullable=false, name="BTBR")
	public String BTBR;
	
	@Column(nullable=false, name="BUB_BnJ")
	public String BUB_BnJ;
	
	@Column(nullable=false, name="C3H_HeH")
	public String C3H_HeH;
	
	@Column(nullable=false, name="C3H_HeJ")
	public String C3H_HeJ;
	
	@Column(nullable=false, name="C57BL_10J")
	public String C57BL_10J;
	
	@Column(nullable=false, name="C57BL_6NJ")
	public String C57BL_6NJ;
	
	@Column(nullable=false, name="C57BR_cdJ")
	public String C57BR_cdJ;
	
	@Column(nullable=false, name="C57L_J")
	public String C57L_J;
	
	@Column(nullable=false, name="C58_J")
	public String C58_J;
	
	@Column(nullable=false, name="CAST_EiJ")
	public String CAST_EiJ;
	
	@Column(nullable=false, name="CBA_J")
	public String CBA_J;
	
	@Column(nullable=false, name="DBA_1J")
	public String DBA_1J;
	
	@Column(nullable=false, name="DBA_2J")
	public String DBA_2J;
	
	@Column(nullable=false, name="FVB_NJ")
	public String FVB_NJ;
	
	@Column(nullable=false, name="I_LnJ")
	public String I_LnJ;
	
	@Column(nullable=false, name="KK_HiJ")
	public String KK_HiJ;
	
	@Column(nullable=false, name="LEWES_EiJ")
	public String LEWES_EiJ;
	
	@Column(nullable=false, name="LP_J")
	public String LP_J;
	
	@Column(nullable=false, name="MOLF_EiJ")
	public String MOLF_EiJ;
	
	@Column(nullable=false, name="NOD_ShiLtJ")
	public String NOD_ShiLtJ;
	
	@Column(nullable=false, name="NZB_B1NJ")
	public String NZB_B1NJ;
	
	@Column(nullable=false, name="NZO_HlLtJ")
	public String NZO_HlLtJ;
	
	@Column(nullable=false, name="NZW_LacJ")
	public String NZW_LacJ;
	
	@Column(nullable=false, name="PWK_PhJ")
	public String PWK_PhJ;
	
	@Column(nullable=false, name="RF_J")
	public String RF_J;
	
	@Column(nullable=false, name="SEA_GnJ")
	public String SEA_GnJ;
	
	@Column(nullable=false, name="SPRET_EiJ")
	public String SPRET_EiJ;
	
	@Column(nullable=false, name="ST_bJ")
	public String ST_bJ;
	
	@Column(nullable=false, name="WSB_EiJ")
	public String WSB_EiJ;
	
	@Column(nullable=false, name="ZALENDE_EiJ")
	public String ZALENDE_EiJ;
	
	
	public static List<Variant> finemap(int chr, Integer start, Integer end, List<String> consequences, List<String> strains1, List<String> strains2, int thr1, int thr2){
		
		EbeanServer server = Ebean.getServer("mousefm");
		
		String queryString =  "chr=" + chr;
		
		
		if(start != null && end != null) {
			queryString += " and pos>=" + start + " and pos<=" + end;
		}
		
		
		if(consequences != null && consequences.size() > 0) {
			
			// Performs not so well
			//queryString += " and CONCAT(\",\", CONSEQUENCES, \",\") REGEXP \",(" + String.join("|", consequences) + "),\"";
			
			
			List<String> cons = new ArrayList<>();
			for(String c : consequences) {
				cons.add("FIND_IN_SET('" + c + "', CONSEQUENCES)");
			}
			
			queryString += " and (" + String.join(" or ", cons) + ")";
		}
		
		
		if(!(strains1.isEmpty() && strains2.isEmpty())) {
			queryString += " and " + String.join(" is not null and ", strains1) + " is not null and " + String.join(" is not null and ", strains2) + " is not null";
			queryString += " and ((" + String.join(" + ", strains1) + ">=" + String.valueOf(strains1.size()-thr1) + " and " + String.join(" + ", strains2) + "<=" + thr2 + ") or " +
							"(" + String.join(" + ", strains2) + ">="+  String.valueOf(strains2.size()-thr2) + " and " + String.join(" + ", strains1) + "<=" + thr1 + "))";
		}
		
		
		//System.out.println(queryString);
		
		Query<Variant> query = server.createQuery(Variant.class).where().raw(queryString).query();
		
		return query.findList();
	}
}
