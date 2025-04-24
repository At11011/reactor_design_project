### A Pluto.jl notebook ###
# v0.20.6

#> [frontmatter]
#> title = "Reactor Design Project"
#> tags = ["Nuclear Engineering"]
#> date = "2025-04-24"
#> description = "For NUEN 601"
#> 
#>     [[frontmatter.author]]
#>     name = "Nathaniel Thomas"
#>     url = "https://github.com/At11011"

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ f7d3d06a-1ec5-11f0-2bd5-39f3f59761b6
using PlutoUI, Measurements, Unitful, Luxor, Colors, Markdown, UnitfulLatexify, Handcalcs, SpecialFunctions, Roots, FunctionZeros, PlutoPlotly, PhysicalConstants.CODATA2018, LinearAlgebra, PlutoExtras, LaTeXStrings, DataFrames

# ╔═╡ 1c367766-8fcf-46ee-89a8-ef7065f7e101
TableOfContents()

# ╔═╡ e00d6872-032c-4ef9-8793-8b95138c47b4
md"""

Adjust the scale of the fuel element diagram by sliding this slider.

$(@bind figscale PlutoUI.Slider(1:1000, default=300, show_value=true))
"""

# ╔═╡ aef066bc-294b-4464-aedd-2f9039f68ca2
md"""
## Fuel element diagram
"""

# ╔═╡ ebb5a02c-bed2-4005-905d-d74476abe85c
function create_markdown_table(columns...; headers=nothing)
    # Determine number of rows and columns
    num_cols = length(columns)
    num_rows = maximum(length(col) for col in columns)
    
    # Create default headers if none provided
    if isnothing(headers)
        headers = ["Column $i" for i in 1:num_cols]
    elseif length(headers) != num_cols
        error("Number of headers must match number of columns")
    end
    
    # Start building the table with headers
    table = "| " * join(headers, " | ") * " |\n"
    
    # Add separator row
    table *= "| " * join(["---" for _ in 1:num_cols], " | ") * " |\n"
    
    # Add data rows
    for i in 1:num_rows
        row = []
        for j in 1:num_cols
            # Check if the column has this row
            if i <= length(columns[j])
                push!(row, string(columns[j][i]))
            else
                push!(row, "")
            end
        end
        table *= "| " * join(row, " | ") * " |\n"
    end
    
    return table
end;

# ╔═╡ ed80858a-5297-42dd-8a05-472897c675dc
md"""
## Design Parameters

This reactor will be designed using Julia Pluto, a reactive notebook-based interface for the Julia programming language. It allows for live adjustment of variables and reactive feedback based on those adjustments. 

The design parameters are provided below. Note that when any value is changed, the 
new value is reflected throughout the notebook. If a different design parameter is desired, simply change the value in the definition below.
"""

# ╔═╡ 1f47fc1f-7a16-4156-ac06-0543d5866121
begin
	ρ_U = uraniumρ = ρ_f = fueldensity = 17.0u"g/cm^3"
	h_core = activecoreheight = 50.0u"cm"
	d_core = corediameter = 100.0u"cm"
	r_core = coreradius = corediameter / 2
	extrapolationcorrection = 15.0u"cm"
	r_extr = extrcoreradius = coreradius + extrapolationcorrection
	extrhalfcoreheight = activecoreheight/2 + extrapolationcorrection
	h_extr = extrhalfcoreheight * 2
	d_fe = fuelelementouterdiameter = 0.90u"cm"
	r_pf = latticepitchtofuelratio = 1.4
	claddingthickness = 0.05u"cm"
	d_f = fueldiameter = fuelelementouterdiameter - 2*claddingthickness
end;

# ╔═╡ 2940ea19-cd89-455a-8792-2f48d7790b40
@draw begin
	textspace = 5
	fuelradius = figscale*ustrip(fueldiameter/2)
	coolantradius = latticepitchtofuelratio * fuelradius
	cladradius = figscale*ustrip(fuelelementouterdiameter/2)

	# Draw coolant
	pentagonrotation = ustrip(uconvert(u"rad", 30u"°"))
	sidelength = coolantradius / √3 * 2
	pentagon = ngonside(O, sidelength, 6, vertices=true)
	sethue("blue")
	rotate(pentagonrotation)
	Luxor.poly(pentagon, action = :fill, close=true)
	strokepath()
	rotate(-pentagonrotation)
	
	# Draw cladding
	sethue("gray")
	Luxor.circle(O, cladradius; action=:fill)
	
	# Draw fuel element
	sethue("green")
	Luxor.circle(O, fuelradius; action=:fill)
	sethue("black")

	# Element labels
	Luxor.text("Fuel Element", O, halign=:center)
	Luxor.text("Cladding", Luxor.Point(0, cladradius - textspace), halign=:center)
	Luxor.text("Coolant", Luxor.Point(0, coolantradius - textspace), halign=:center)
	
	function drawscalebar(uplength, radius, text)
		move(radius, 0) # Right bar
		rline(Luxor.Point(0, uplength))
		strokepath()
		move(-radius, 0) # Left bar
		rline(Luxor.Point(0, uplength))
		strokepath()
		move(-radius, uplength) # Top bar
		rline(Luxor.Point(radius * 2, 0))
		strokepath()
		Luxor.text(text, Luxor.Point(0, uplength - textspace),halign=:center)
	end
	
	# Draw fuel scale bars
	drawscalebar(-figscale * 0.7, fuelradius, "$fueldiameter")

	# Draw cladding scale bars
	drawscalebar(-figscale * 0.8, cladradius, "$fuelelementouterdiameter")

	# Draw coolant scale bars
	drawscalebar(-figscale * 0.9, coolantradius,"$(round(typeof(1.0u"cm"), latticepitchtofuelratio * fueldiameter, digits=5))")
	
end

# ╔═╡ 4c77a865-46d7-4cee-974e-ad6177ac5435
begin
	k_eff_target = 1.035 ± 0.005
	operationtime = 30u"yr"
	δx_x = 10u"percent"
	peakingfactor = 1.2
end;

# ╔═╡ 40af7228-e163-4d0f-8cd3-f20389558e64
begin
	group = 1:8;
	lethargywidth = [1.5, 1.0, 1.0, 1.0, 1.0, 1.0, 3.0, missing];
	lowerenergy = [2200, 820, 300, 110, 40, 15, 0.750, 0]u"keV";
	χ⃗ = fissionspectrum = [0.365, 0.396, 0.173, 0.050, 0.012, 0.003, 0.001, 0];
end;

# ╔═╡ 91ba4b60-c65d-41af-b293-5248c14b6cce
Markdown.parse("""
## Project Requirements
**Power selection**

You will need to select the power level that would be appropriate for a competitive commercial deployment:
 - Select an application for your reactor
 - Identify a competitive power level for your reactor to be commercially competitive and justify your choice.

**Using the provided fuel element characteristics, design the FMR core with BOL**

``k_{eff} = $k_eff_target ``


**DETERMINE:**

 - Number of fuel elements in the core
 - Content of U-235 (\$x = ?\$) required to yield the prescribed multiplication
 - Sensitivity  with respect to fluctuations of U-235 content 
 - Sensitivity  with respect to fluctuations of core dimensions (radius and height)
 - Total fuel loading of the reactor (kg) and the U-235 loading (in kg)
 - Consider sodium properties and determine acceptable inlet, outlet and bulk (average) in-core coolant temperatures yielding the maximized core outlet coolant temperature in the hottest channel. No sodium boiling permitted.
	
	Justify your choices.
	
	Assume the peaking factor value of $peakingfactor.
	
	Assess the mass flow rate, w, kg/s, needed for the selected above in-core coolant temperatures.
	
	Consistent with the above-chosen and estimated parameters, estimate the maximum fuel centerline temperature in the hottest channel.
	
	Compare that to the relevant material properties.
	
	Discuss the values, make adjustments as needed and finalize values for the in-core mass flow rate and temperatures to maximize the core outlet coolant temperature in the hottest channel without boiling. Justify the chosen margin from boiling conditions.

**Extra credit (50 points):** develop simple MCNP model of your reactor core and perform depletion analysis and assess the core lifetime consistent with your selected power level. Estimate your fresh core reactivity coefficients. Plot energy spectrum at BOL. 

Perform criticality search to determine the min. enrichment value and the corresponding BOL ``k_{eff}`` that yields $operationtime for the core lifetime. Estimate the corresponding attained fluence value and discuss feasibility of operating this reactor for $operationtime. 

*Assumptions*

1. Multigroup Zero-Dimensional Model of the Reactor Core ($(length(group)) energy groups)
2. Assume no reflector
3. For SS316 assume that it can be replaced with iron
4. Assume that the provided 8-group cross sections are at the operational conditions

**YOUR REPORT MUST CONTAIN THE FOLLOWING:**

1. The 8-group set of homogenized cross-sections representing the reactor core
2. Plot of the actual energy flux normalized to the specified power level
3. Estimated number of fuel elements in the core
4. Plot of ``k_{eff}`` as a function of U-235 content in the core
5. Compute value of ``\\delta k_{eff} / k_{eff}`` for ``\\delta x / x =`` $δx_x 
6. Compute value of ``\\delta k_{eff} / k_{eff}`` as a function of fluctuations of core dimensions
7. The required fraction of U-235 to provide ``k_{eff}`` = $k_eff_target
8. Total fuel loading of the core (kg) and the corresponding mass of U-235 (kg)
9. Results of the thermal core evaluation (inlet, outlet, average (bulk) in-core coolant temperatures for the hottest channel and for the average channel, in-core mass flow rate, max fuel centerline temperature). Discuss your results.
10. Plots of in-core temperature distributions – coolant, cladding, fuel temperatures for the hottest channel.
11. Summary table of your design parameters and the design overview.
12. **Extra credit (50 points)** – results of your MCNP depletion analysis including core lifetime, fresh core energy distribution (spectrum) and reactivity coefficients (fuel and sodium), minimum enrichment value that yields $operationtime for the core lifetime and the corresponding BOL ``k_{eff}``. Discussion of your feasibility analysis of operating this reactor for $operationtime and how this fits with your selected reactor deployment application.
""")

# ╔═╡ 043779a5-5e64-48cb-b5a6-1eaf401f3019
Markdown.parse(create_markdown_table(group, lethargywidth, lowerenergy, fissionspectrum, headers=["Group", "Lethargy Width, Δu", "Lower Energy", "Fission Spectrum"]))

# ╔═╡ fb7d0c7a-21ce-4390-b3c3-9860184f5ab1
begin
	material(material) = vcat([material], fill("", 7));
	propheaders = ["Material", "Group", "σₜᵣ", "σγ", "σf", "σₛᵣ", "νf"];
end;

# ╔═╡ 7dcd34eb-3651-4d1a-9516-dba9ba5617d8
begin
	sodiumσtr = [1.5, 2.2, 3.6, 3.5, 4.0, 3.9, 7.3, 3.2]u"b"
	sodiumσγ = [0.0050, 0.0002, 0.0004, 0.0010, 0.0010, 0.0010, 0.0090, 0.0080]u"b"
	sodiumσf = fill(missing, 8)
	sodiumσsr = [0.623, 0.6908, 0.4458, 0.2900, 0.3500, 0.3000, 0.0400, 0.0000]u"b"
	sodiumνf = fill(missing, 8)
	sodiumprops = (material("Sodium"), group, sodiumσtr, sodiumσγ, sodiumσf, sodiumσsr, sodiumνf)
end;

# ╔═╡ cc03f841-80b8-481b-8b7c-0674e9aa35ed
Markdown.parse(create_markdown_table(sodiumprops..., headers=propheaders))

# ╔═╡ c994fcf1-e8a2-433c-8c52-6f018d35b844
begin
	ironσtr = [2.2, 2.1, 2.4, 3.1, 4.5, 6.1, 6.9, 10.4]u"b"
	ironσγ = [0.0200, 0.0030, 0.0050, 0.0060, 0.0080, 0.0120, 0.0320, 0.0200]u"b"
	ironσf = fill(missing, 8)
	ironσsr = [1.0108, 0.4600, 0.1200, 0.1400, 0.2800, 0.0700, 0.0400, 0.0000]u"b"
	ironνf = fill(missing, 8)
	ironprops = (material("Iron"), group, ironσtr, ironσγ, ironσf, ironσsr, ironνf)
end;

# ╔═╡ fb41b04b-0ffb-4686-915d-84f846820e4b
Markdown.parse(create_markdown_table(ironprops..., headers=propheaders))

# ╔═╡ 18370f53-bb76-4a97-a314-1b941d848bc3
begin
	u238σtr = [4.3, 4.8, 6.3, 9.4, 11.7, 12.7, 13.1, 11.0]u"b"
	u238σγ = [0.0100, 0.0900, 0.1100, 0.1500, 0.2600, 0.4700, 0.8400, 1.4700]u"b"
	u238σf = vcat([0.58, 0.20], fill(0.0, 6))u"b"
	u238σsr = [2.293, 1.4900, 0.3759, 0.2935, 0.2000, 0.0900, 0.0100, 0.0000]u"b"
	u238νf = vcat([2.91, 2.58], fill(0.0, 6))
	u238props = (material("U-238"), group, u238σtr, u238σγ, u238σf, u238σsr, u238νf)
end;

# ╔═╡ 9debb5ed-18cd-4252-a5e2-3c81833d9d6d
Markdown.parse(create_markdown_table(u238props..., headers=propheaders))

# ╔═╡ 796f5e11-c68c-454b-beb8-2630a909dd5c
begin
	u235σtr = [4.2, 4.8, 6.2, 8.7, 11.7, 13.9, 17.7, 33.0]u"b"
	u235σγ = [0.0400, 0.0900, 0.18, 0.32, 0.53, 0.79, 1.71, 5.76]u"b"
	u235σf = [1.23, 1.24, 1.18, 1.40, 1.74, 2.16, 4.36, 15.06]u"b"
	u235σsr = [1.3940, 0.8530, 0.4746, 0.3120, 0.1500, 0.0800, 0.0100, 0.0000]u"b"
	u235νf = vcat([2.90, 2.59, 2.48, 2.44, 2.43], fill(2.42, 3))
	u235props = (material("U-235"), group, u235σtr, u235σγ, u235σf, u235σsr, u235νf)
end;

# ╔═╡ 48959bc2-8051-4a16-b6b4-85d208703207
Markdown.parse(create_markdown_table(u235props..., headers=propheaders))

# ╔═╡ 940921b5-c0cb-4841-b6ee-2f0d9de20d98
begin
	sodiumscatter = [ 	0.0000 0.5200 0.0900 0.0030 0.0090 0.0010 0.0000 0.0000
						0.0000 0.0000 0.6900 0.0000 0.0004 0.0004 0.0000 0.0000
						0.0000 0.0000 0.0000 0.4400 0.0050 0.0008 0.0000 0.0000
						0.0000 0.0000 0.0000 0.0000 0.2900 0.0000 0.0000 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.3500 0.0000 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.3000 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0400
						0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000]u"b"
	ironscatter = [ 	0.0000 0.7500 0.2000 0.0500 0.0100 0.0008 0.0000 0.0000
						0.0000 0.0000 0.3300 0.1000 0.0200 0.0100 0.0000 0.0000
						0.0000 0.0000 0.0000 0.1200 0.0000 0.0000 0.0000 0.0000
						0.0000 0.0000 0.0000 0.0000 0.1400 0.0000 0.0000 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.2800 0.0000 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0700 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0400
				  		0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000]u"b"
	u238scatter = [ 	0.0000 1.2800 0.7800 0.2000 0.0300 0.0030 0.0000 0.0000
						0.0000 0.0000 1.0500 0.4200 0.0100 0.0100 0.0000 0.0000
						0.0000 0.0000 0.0000 0.3300 0.0400 0.0050 0.0009 0.0000
						0.0000 0.0000 0.0000 0.0000 0.2900 0.0030 0.0005 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.1800 0.0200 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0900 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0100
				  		0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000]u"b"
	u235scatter = [ 	0.0000 0.7200 0.4800 0.1600 0.0300 0.0040 0.0000 0.0000
						0.0000 0.0000 0.7200 0.1200 0.0100 0.0030 0.0000 0.0000
						0.0000 0.0000 0.0000 0.4300 0.0400 0.0040 0.0006 0.0000
						0.0000 0.0000 0.0000 0.0000 0.2900 0.0200 0.0020 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.1400 0.0100 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0800 0.0000
						0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0100
				  		0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000]u"b"
end;

# ╔═╡ 21879b35-ef24-478c-a8a4-a60f3a882804
md"""
!!! info "Note on how scattering matrices work"

	The scattering matrices represent the inter-group scattering cross-sections.

	The row represents the origin group, and the column represents the destination group.

For example, for sodium scattering, the cross section of scattering from group 1 to group 2 is `sodiumscatter[1, 2] = `$(sodiumscatter[1,2]).
"""

# ╔═╡ 9b4827d8-209c-444c-990e-a877669062d0
begin
	ρ_Na = sodiumρ = 0.927u"g/cm^3"
	M_Na = sodiumM = 22.990u"g/mol"
	ρ_Fe = ironρ = 7.874u"g/cm^3"
	M_Fe = ironM = 55.845u"g/mol"
	# uraniumρ = 19.050u"g/cm^3"
	M_U = uraniumM = 238.03u"g/mol"
end;

# ╔═╡ 7e0408f9-b69a-409f-9a5e-19bf0d543f66
P_f = targetpower = 1u"MW";

# ╔═╡ e5dc3d5e-3748-460b-9ad7-ecb591cba7ad
md"""
# Reactor Design Project

The fast Micro Reactor (FMR) is a fast sodium cooled reactor (you can think of this design as a version of the TerraPower Natrium design). This system is considered because of its technical maturity and existing international experience in operating sodium-cooled fast reactors. **Let’s look into this technology and design the FMR core.**

| 		      	| 				|
| ------------- | ------------- |
| Fuel element arrangement | Triangular lattice |
| Type | Cylindrical Fuel Element |
| Fuel, metal | ($x \cdot ^{235}\mathrm{U} + (1-x)\cdot ^{238}\mathrm{U}$) |
| Fuel Density (metal form) | $fueldensity |
| Coolant | Sodium |
| Cladding and Structure | Stainless Steel, Type 316 |
| Active core height (fuel element length) | $activecoreheight |
| Core Diameter | $corediameter |
| Extrapolation Correction for Core Dimension | $extrapolationcorrection |
| Fuel Element Outer Diameter (fuel + cladding) | $fuelelementouterdiameter | 
| Lattice Pitch-to-Fuel Element Outer Diameter Ratio | $latticepitchtofuelratio |
| Cladding Thickness | $claddingthickness |
| Thermal Power ($\mathrm{MW_{th}}$) | $P_f |

> You will need to select the power level that would be appropriate for a competitive commerical deployment:
>- Select an application for your reactor
>- Identify a competitive power level for your reactor to be commercially competitive and justify your choice.
"""

# ╔═╡ 651bbcdc-7495-4899-b8d4-9627060eba22
md"""
## Target power
A target power of $targetpower was chosen, as this provides a balance between reactor size and flux that can be used for isotope production.
"""

# ╔═╡ 086e0d46-db87-4cdc-9d34-4056e0587450
md"""
## Zero dimensional multigroup diffusion model without up-scattering

To calculate ``k_{eff}`` and other parameters, the zero-dimensional multigroup diffusion model will be used. First, the reactor will be homogenized, including the material cross sections, then the resultant values will be used to solve for the energy-dependant flux in the reactor.
"""

# ╔═╡ 070e2f85-b2a2-4ef8-a9ba-f8960aa5cd51
begin
	@handcalcs begin
		A_circ = π*(d_core / 2)^2
		s_sqr = √A_circ
		p_fuel = r_pf * d_fe
		N¹_FE = (s_sqr/p_fuel)^2
	end
end

# ╔═╡ 8d1dfed1-64ce-41be-9fa9-1f7e827879ef
N_FE = Int(round(N¹_FE, sigdigits=2))

# ╔═╡ 4bab2fa5-6b1b-4c9d-b8e4-e7cbcf085c84
md"""
### Homogenization

(p. 416)

1. Start by dividing the reactor into a periodic array of identical multiregion unit cells of volume $V_{Cell}$.

The number of fuel elements was found by converting the area of the circular cross section of the reactor core to a square, then finding the number of elements required to fill the square with the fuel element pitch that is specified in the reactor design. Using this technique, the number of fuel elements was found to be about $N_FE.

"""

# ╔═╡ a5aa28d1-6149-40e4-bfd9-c3d02484f639
x_slider = @bind enrichment Slider(0:0.001:1, default = 0.798, show_value=true);

# ╔═╡ de303102-9a99-44ca-b58d-99b677095ab1
md"""
Enrichment can be chosen by adjusting the slider below:

*x = enrichment =* $x_slider

Notice how the ``k_{eff}`` value changes in real time as you adjust the slider. 
"""

# ╔═╡ 82d3a3cb-893a-4590-bbd4-aa432edca788
x = enrichment;

# ╔═╡ cc534d9d-7e75-4d3e-96eb-461c39880349
@handcalcs begin
	V_Core = π * (d_core/2)^2 * h_core
	V_FE = π * (d_fe/2)^2 * h_core
	V_C = π * ((d_fe/2)^2 - (d_f/2)^2) * h_core
	V_F = V_FE - V_C
	V_Cell = (1 / N_FE)* V_Core
	V_M = (V_Core - (N_FE * V_FE)) / N_FE
end

# ╔═╡ f6155a08-bf20-4635-bc75-13c3ec446728
md"""
	2. Calculate the flux disadvantage factors.

!!! info "Approximation"
	Disadvantage factors have complicated solutions. Assume that they are just volume ratios. This is likely still somewhat accurate, since absorbtion is not as strong in a fast-spectrum reactor.
"""

# ╔═╡ 61a5bddd-7560-450e-80d2-19f1ca391d68
@handcalcs begin
	ζᶠ_Cell = V_F / V_Cell
	ζᶜ_Cell = V_C / V_Cell
	ζᵐ_Cell = V_M / V_Cell
	ζᶠ_Cell + ζᶜ_Cell + ζᵐ_Cell
end precision = 3

# ╔═╡ 8968d66b-ae18-4527-bcf6-0bc0d255d4b0
md"""
	3. Homogenize the multiregion unit cell by averaging group constants that characterize the material over the spacial flux distribution.
"""

# ╔═╡ 36161f25-7fd2-4d74-9d70-918ac68f9563
begin
	N_A = AvogadroConstant
	
	σᴺᵃ_tr = uconvert.(u"cm^2", sodiumσtr)
	σᶠᵉ_tr = uconvert.(u"cm^2", ironσtr)
	σᵁ²³⁵_tr = uconvert.(u"cm^2", u235σtr)
	σᵁ²³⁸_tr = uconvert.(u"cm^2", u238σtr)
	
	σᴺᵃ_γ = uconvert.(u"cm^2", sodiumσγ)
	σᶠᵉ_γ = uconvert.(u"cm^2", ironσγ)
	σᵁ²³⁵_γ = uconvert.(u"cm^2", u235σγ)
	σᵁ²³⁸_γ = uconvert.(u"cm^2", u238σγ)

	σᴺᵃ_sr = uconvert.(u"cm^2", sodiumσsr)
	σᶠᵉ_sr = uconvert.(u"cm^2", ironσsr)
	σᵁ²³⁵_sr = uconvert.(u"cm^2", u235σsr)
	σᵁ²³⁸_sr = uconvert.(u"cm^2", u238σsr)

	σᵁ²³⁵_f = uconvert.(u"cm^2", u235σf)
	σᵁ²³⁸_f = uconvert.(u"cm^2", u238σf)

	σᴺᵃ_s = uconvert.(u"cm^2", sodiumscatter)
	σᶠᵉ_s = uconvert.(u"cm^2", ironscatter)
	σᵁ²³⁵_s = uconvert.(u"cm^2", u235scatter)
	σᵁ²³⁸_s = uconvert.(u"cm^2", u238scatter)
	
	@handcalcs begin
		N_Fe = ρ_Fe * N_A / M_Fe;
		N_Na = ρ_Na * N_A / M_Na
		N_U = ρ_U * N_A / M_U
		
		Σᴺᵃ_tr = N_Na*σᴺᵃ_tr
		Σᶠᵉ_tr = N_Na*σᶠᵉ_tr
		Σᵁ²³⁵_tr = N_Na*σᵁ²³⁵_tr
		Σᵁ²³⁸_tr = N_Na*σᵁ²³⁸_tr

		Σᴺᵃ_γ = N_Na*σᴺᵃ_γ
		Σᶠᵉ_γ = N_Na*σᶠᵉ_γ
		Σᵁ²³⁵_γ = N_Na*σᵁ²³⁵_γ
		Σᵁ²³⁸_γ = N_Na*σᵁ²³⁸_γ	

		Σᴺᵃ_sr = N_Na*σᴺᵃ_sr
		Σᶠᵉ_sr = N_Na*σᶠᵉ_sr
		Σᵁ²³⁵_sr = N_Na*σᵁ²³⁵_sr
		Σᵁ²³⁸_sr = N_Na*σᵁ²³⁸_sr

		Σᵁ²³⁵_f = N_Na*σᵁ²³⁵_f
		Σᵁ²³⁸_f = N_Na*σᵁ²³⁸_f

		Σᴺᵃ_s = N_Na*σᴺᵃ_s
		Σᶠᵉ_s = N_Na*σᶠᵉ_s
		Σᵁ²³⁵_s = N_Na*σᵁ²³⁵_s
		Σᵁ²³⁸_s = N_Na*σᵁ²³⁸_s
	end precision = 5
end

# ╔═╡ 0e99355d-b149-4641-b69e-611effa644b0
@handcalcs begin
	Σ_tr = ζᶜ_Cell*Σᶠᵉ_tr + ζᵐ_Cell*Σᴺᵃ_tr + ζᶠ_Cell*(Σᵁ²³⁵_tr*x + (1 - x)*Σᵁ²³⁸_tr)
	Σ_γ = ζᶜ_Cell*Σᶠᵉ_γ + ζᵐ_Cell*Σᴺᵃ_γ + ζᶠ_Cell*(Σᵁ²³⁵_γ*x + (1 - x)*Σᵁ²³⁸_γ)
	Σ_sr = ζᶜ_Cell*Σᶠᵉ_sr + ζᵐ_Cell*Σᴺᵃ_sr + ζᶠ_Cell*(Σᵁ²³⁵_sr*x + (1 - x)*Σᵁ²³⁸_sr)
	Σ_f = ζᶠ_Cell*(Σᵁ²³⁵_f*x + (1 - x)*Σᵁ²³⁸_f)
	Σ_s = ζᶜ_Cell*Σᶠᵉ_s + ζᵐ_Cell*Σᴺᵃ_s + ζᶠ_Cell*(Σᵁ²³⁵_s*x + (1 - x)*Σᵁ²³⁸_s)
end precision = 5 len = :long

# ╔═╡ 6d5bc584-3774-4df6-a15a-446263a943e2
md"""

## Zero-dimensional multi-group calculations

The following equations will be applied to calculate the value of ``k_{eff}``.

$$L_{8\times 8}\vec\phi = \vec\chi$$

$$L_{8\times 8} = \begin{pmatrix}
 D_1B_g^2 + R_{R,1} & 0 & 0 & \dots & 0 \\
 -\Sigma_{s,1\rightarrow 2} & D_2B_g^2 + \Sigma_{R,2} & 0 & \dots & 0 \\
 -\Sigma_{s,1\rightarrow 3} & -\Sigma_{s,2\rightarrow 3} & D_3B_g^2 + \Sigma_{R,3} & \dots & 0 \\
\dots & \dots & \dots & \dots & \dots \\
-\Sigma_{s,1\rightarrow 8} & -\Sigma_{s,2\rightarrow 8} & -\Sigma_{s,3\rightarrow 8} &  \dots &  D_8B_8^2 + \Sigma_{R,8} \\
\end{pmatrix}_{8\times 8}$$

$$\vec\phi = \begin{bmatrix}
	\phi_1 \\ \phi_2 \\ \phi_3 \\ \dots \\ \phi_8
\end{bmatrix}_8$$

$$\vec\chi_8 = \begin{bmatrix}
	\chi_1 \\ \chi_2 \\ \chi_3 \\ \dots \\ \chi_8
\end{bmatrix}_8$$

$$\vec\phi = L_{8\times 8}^{-1} \cdot \vec \chi$$

$$k_{eff} = \sum_{h=1}^G(\nu_f\Sigma_f)_h\phi_h$$

(p. 459)
"""

# ╔═╡ eff59af2-a578-4a9d-ab6b-1aae868eaa23
begin
	D_g(Σ_tr) = 1 / (3*Σ_tr);
	Θ₁ = besselj_zero(0, 1)
	R(r, z) = besselj0(r * Θ₁ / r_extr)*cos(z * π / h_extr);
end;

# ╔═╡ 87029787-4d53-4f59-9eba-50146f968832
md"""
A plot of the flux shape of the reactor as a function of height and radius is provided below.
"""

# ╔═╡ 4df4c616-7f94-4e44-a003-a3d336429e66
let
	numvalues = 1000;
	rvalues = range(0u"cm", extrcoreradius, length=numvalues);
	zvalues = range(-extrhalfcoreheight, extrhalfcoreheight, length=numvalues);
	Rmatrix = [R(r,z) for r ∈ rvalues, z ∈ zvalues]
	plot(
    surface(
        x=ustrip.(rvalues), 
        y=ustrip.(zvalues), 
        z=ustrip.(Rmatrix),
        colorscale="Viridis"
    ),
    Layout(
        title="Plot of R(r,z)",
        scene=attr(
            xaxis_title="r ($(unit(rvalues[1])))",
            yaxis_title="z ($(unit(zvalues[1])))",
            zaxis_title="R(r,z)"
        )
    )
)
end

# ╔═╡ 941ee37e-0e43-44a6-ae7f-727577a9817e
@handcalcs begin
	# Bg² = (Θ₁ / (r_extr))^2 + (π / h_extr)^2
	Bg² = (Θ₁ / (r_core))^2 + (π / h_core)^2
end precision = 4

# ╔═╡ 8e9ca7e9-f75f-476e-93fb-09fe84db723a
L_matrix = diagm(0 => D_g.(Σ_tr) * Bg² .+ Σ_sr) + Σ_s';

# ╔═╡ bc356317-fc2c-480b-b716-b90f0ff78096
χ⃗

# ╔═╡ b0e1454f-f8a4-4540-972a-c78abee4e505
L"""
L_{8\times 8} = %$(latexify(round.(typeof(1.0u"cm^-1"), L_matrix, sigdigits=4)))
"""

# ╔═╡ 9098e727-ad74-436b-a53f-36e7e2c37518
ϕ⃗ = L_matrix^-1 * χ⃗

# ╔═╡ 3132ebbd-2fc4-4b58-9cbb-34f8e9715c78
L"""
\phi\vec = L_{8\times 8}^{-1} \cdot \vec\chi = %$(latexify(round.(typeof(1.0u"cm"), ϕ⃗, sigdigits=4)))
"""

# ╔═╡ 3bf956b6-f767-44d5-9135-046171215790
k_eff = sum(@. (x * u235νf * Σᵁ²³⁵_f + (1 - x) * u238νf * Σᵁ²³⁸_f) * ϕ⃗);

# ╔═╡ 89b877cd-615a-4fab-89a8-ae8f7a46a969
k_eff

# ╔═╡ ea345c72-25bf-42f2-bf7e-6740876559f9
if k_eff_target.val  - k_eff_target.err < k_eff < k_eff_target.val  + k_eff_target.err 
md"""
!!! correct "Correct"
$k_eff is approximately equal to $k_eff_target
"""
elseif k_eff > k_eff_target
md"""
!!! danger "Incorrect - Too Large"
$k_eff is larger than $k_eff_target
"""
else
md"""
!!! danger "Incorrect  - Too Small"
	``k_{eff}`` value too small
$k_eff is smaller than $k_eff_target
"""
end

# ╔═╡ b594117a-c70d-4486-94a2-4990bf145e1e
Markdown.parse("""
### Final ``k_{eff}`` = $(latexify(round(k_eff, sigdigits=5)))
""")

# ╔═╡ 7b8edcf9-de43-4ece-aaae-8c9b88d846fc
md"""
### ``k_{eff}`` versus enrichment

A function to find ``k_{eff}`` from enrichment was developed using the technique from above. This is used to develop a plot of ``k_{eff}`` as a function of enrichment.
"""

# ╔═╡ 2a1b3028-d3ec-4762-92e9-be038e28062a
function k_eff_from_enrichment(x)
	Σ_tr = ζᶜ_Cell*Σᶠᵉ_tr + ζᵐ_Cell*Σᴺᵃ_tr + ζᶠ_Cell*(Σᵁ²³⁵_tr*x + (1 - x)*Σᵁ²³⁸_tr)
	Σ_sr = ζᶜ_Cell*Σᶠᵉ_sr + ζᵐ_Cell*Σᴺᵃ_sr + ζᶠ_Cell*(Σᵁ²³⁵_sr*x + (1 - x)*Σᵁ²³⁸_sr)
	Σ_f = ζᶠ_Cell*(Σᵁ²³⁵_f*x + (1 - x)*Σᵁ²³⁸_f)
	Σ_s = ζᶜ_Cell*Σᶠᵉ_s + ζᵐ_Cell*Σᴺᵃ_s + ζᶠ_Cell*(Σᵁ²³⁵_s*x + (1 - x)*Σᵁ²³⁸_s)
	L_matrix = diagm(0 => D_g.(Σ_tr) * Bg² + Σ_sr) + Σ_s'
	ϕ⃗ = L_matrix^-1 * χ⃗
	k_eff_1 = sum(@. (x * u235νf * Σᵁ²³⁵_f + (1 - x) * u238νf * Σᵁ²³⁸_f) * ϕ⃗)
end

# ╔═╡ 16b9dd3f-6eaf-4390-ada2-21a3a1c0dc4d
target_enrichment = find_zero((x) -> k_eff_from_enrichment(x) - k_eff_target.val, 0.80)

# ╔═╡ e7900188-612e-4d7d-87e6-a5a87fafb496
target_enrichment

# ╔═╡ 24321c2b-3302-4823-9f6a-fd712dbab041
k_eff_versus_enrichment_plot = let
	enrichment_values = range(0, 1, 100)
	k_eff_values = k_eff_from_enrichment.(enrichment_values)
	k_eff_target_value = fill(k_eff_target.val, length(enrichment_values))
	y_upper = fill(k_eff_target.val + k_eff_target.err, length(enrichment_values))
	y_lower = fill(k_eff_target.val - k_eff_target.err, length(enrichment_values))
	
	fig = Plot(Layout(
		height = 600, 
		title=L"\text{Plot of } k_{eff} \text{ versus U-235 enrichment}",
        xaxis=attr(title="U-235 Enrichment", gridcolor="lightgray"),
        yaxis=attr(title=L"k_{eff}", gridcolor="lightgray"),
        template="simple_white",
    	legend=attr(x=0.01, y=0.99, bgcolor="rgba(255,255,255,0.5)",bordercolor="gray")
	))

	# Add the shaded error region first (so it appears behind the lines)
    add_trace!(fig, scatter(
        x=enrichment_values, 
        y=y_upper,
        mode="lines",
        line=attr(width=0),
        showlegend=false
    ))
    
    add_trace!(fig, scatter(
        x=enrichment_values,
        y=y_lower,
        mode="lines",
        line=attr(width=0),
        fill="tonexty",
        fillcolor="rgba(255,0,0,0.2)",
        name=L"k_{eff} \text{ target uncertainty (±%$(k_eff_target.err))}"
    ))
	
	add_trace!(fig, scatter(
        x=enrichment_values, 
        y=k_eff_values, 
        mode="lines", 
        line=attr(color="blue", width=2),
        name=L"k_{eff}"
    ))
	
	add_trace!(fig, scatter(
        x=enrichment_values, 
		y=k_eff_target_value,
        mode="lines", 
        line=attr(color="red", width=2, dash="dash"),
        name="k_eff target"
    ))

	add_trace!(fig, scatter(
        x=[target_enrichment, target_enrichment], 
		y=[minimum(k_eff_values), maximum(k_eff_values)],
        mode="lines", 
        line=attr(color="green", width=2, dash="dash"),
        name="k_eff enrichment target ($(round(target_enrichment, digits=5)))"
    ))

	fig
end

# ╔═╡ bf17d087-6ef2-4384-9f77-be401705dc27
begin
	E_f = 200u"MeV"
	ϕ_vec = ϕ⃗
	@handcalcs begin
		C_ϕ = @. 3.630 * targetpower / (π*(d_core/2)^2 * h_core * E_f * Σ_f)
	end
	ϕ = uconvert.(u"cm^-1*s^-1", ϕ_vec.*C_ϕ)
end

# ╔═╡ 10fdf51d-57bc-4b86-9c03-dd6d331068b2
md"""
## Fuel loading

Fuel loading was calculated based on fuel density, fuel element geometry, and number of fuel elements.
"""

# ╔═╡ bfc91e5d-de00-437d-a5f4-75e48b4d945a
@handcalcs begin
	m_U = N_FE * π * (d_core/2)^2 * h_core * ρ_U
	m_U235 = x * N_FE * π * (d_core/2)^2 * h_core * ρ_U
end

# ╔═╡ 6917cc86-7849-425e-bcc0-77b4efa30115
ϕ_versus_energy = let
	fig = Plot(Layout(
		height = 700, 
		title=L"\text{Plot of } ϕ \text{ versus energy}",
                xaxis=attr(
            title="Energy ($(unit(lowerenergy[1])))", 
            gridcolor="lightgray",
			tickformat = "h",
            type="log"  # Set x-axis to logarithmic scale
        ),
		yaxis = attr(
            title = "ϕ ($(unit(ϕ[1])))",
            gridcolor = "lightgray",
            tickformat = "0.1e",
			type="log" 
        ),
        template="simple_white",
		margin = attr(l=100, r=10, t=30, b=50, pad=10)
	))

	# Add the shaded error region first (so it appears behind the lines)
    add_trace!(fig, scatter(
        x=ustrip.(lowerenergy), 
        y=ustrip.(ϕ),
        mode="line",
    ))

	fig
end

# ╔═╡ cc1ef5a4-2ab8-444b-8631-05983ac0f30f
function δk_eff_k_eff(x)
	δx = uconvert(NoUnits, δx_x*x)
	δk_eff = k_eff_from_enrichment(x + δx) - k_eff_from_enrichment(x - δx)
	δk_eff_k_eff = δk_eff / k_eff
end

# ╔═╡ 4678c34f-7fbb-41f0-9874-3bf8296b3df6
md"""
## Sensitivity analysis 

``\frac{\delta k_{eff}}{k_{eff}} =`` $(round(δk_eff_k_eff(x), digits=5))
"""

# ╔═╡ 72dd6efd-5129-4a2f-86b5-65145157d5fc
md"""
``k_{eff}`` change in terms of dimension fluctuations
"""

# ╔═╡ b1adf867-f820-4079-bdea-653969b91d58
function k_eff_dimension_fluctuation(δx)
	d_core = corediameter + δx
	h_core = activecoreheight + δx
	
	r_extr = extrcoreradius + δx/2
	h_extr = 2*extrhalfcoreheight + δx

	A_circ = π*(d_core / 2)^2
	s_sqr = √A_circ
	N_FE = round((s_sqr/p_fuel)^2)
	
	V_Core = π * (d_core/2)^2 * h_core
	V_FE = π * (d_fe/2)^2 * h_core
	V_C = π * ((d_fe/2)^2 - (d_f/2)^2) * h_core
	V_F = V_FE - V_C
	V_Cell = (1 / N_FE)* V_Core
	V_M = (V_Core - (N_FE * V_FE)) / N_FE

	ζᶠ_Cell = V_F / V_Cell
	ζᶜ_Cell = V_C / V_Cell
	ζᵐ_Cell = V_M / V_Cell

	Σ_tr = ζᶜ_Cell*Σᶠᵉ_tr + ζᵐ_Cell*Σᴺᵃ_tr + ζᶠ_Cell*(Σᵁ²³⁵_tr*x + (1 - x)*Σᵁ²³⁸_tr)
	Σ_γ = ζᶜ_Cell*Σᶠᵉ_γ + ζᵐ_Cell*Σᴺᵃ_γ + ζᶠ_Cell*(Σᵁ²³⁵_γ*x + (1 - x)*Σᵁ²³⁸_γ)
	Σ_sr = ζᶜ_Cell*Σᶠᵉ_sr + ζᵐ_Cell*Σᴺᵃ_sr + ζᶠ_Cell*(Σᵁ²³⁵_sr*x + (1 - x)*Σᵁ²³⁸_sr)
	Σ_f = ζᶠ_Cell*(Σᵁ²³⁵_f*x + (1 - x)*Σᵁ²³⁸_f)
	Σ_s = ζᶜ_Cell*Σᶠᵉ_s + ζᵐ_Cell*Σᴺᵃ_s + ζᶠ_Cell*(Σᵁ²³⁵_s*x + (1 - x)*Σᵁ²³⁸_s)

	# Bg² = (Θ₁ / (r_extr))^2 + (π / h_extr)^2
	Bg² = (Θ₁ / (r_core))^2 + (π / h_core)^2

	L_matrix = diagm(0 => D_g.(Σ_tr) * Bg² .+ Σ_sr) + Σ_s'
	ϕ⃗ = L_matrix^-1 * χ⃗
	k_eff_fluc = sum(@. (x * u235νf * Σᵁ²³⁵_f + (1 - x) * u238νf * Σᵁ²³⁸_f) * ϕ⃗)

	δk_eff = k_eff_fluc - k_eff
	
	δk_eff_k_eff = δk_eff / k_eff
end

# ╔═╡ 1b24ba31-fc23-4a10-b950-c15c74c012fd
k_eff_dimension_fluctuation_plot = let
	dimensionfluctuation = range(-40, 40, 1000)u"cm"
	k_eff_fluctuation = k_eff_dimension_fluctuation.(dimensionfluctuation)
	fig = Plot(Layout(
		height = 700, 
		title=L"\text{Plot of } \delta k_{eff}/ k_{eff} \text{ versus dimension fluctuation}",
                xaxis=attr(
            title="Dimension fluctuation ($(unit(dimensionfluctuation[1])))", 
            gridcolor="lightgray",
			tickformat = "h",
        ),
		yaxis = attr(
            title = L"δk_{eff}/k_{eff}",
            gridcolor = "lightgray",
        ),
        template="simple_white",
		automargin=true,
	))

    add_trace!(fig, scatter(
        x=ustrip.(dimensionfluctuation), 
        y=ustrip.(k_eff_fluctuation),
        mode="line",
    ))

	fig
end

# ╔═╡ 3f282d1a-55ee-4f39-b554-513bcfa3db0c
# ╠═╡ disabled = true
#=╠═╡
max_flux = C_ϕ*R(0u"cm", 0u"cm")
  ╠═╡ =#

# ╔═╡ 36e07c28-4722-4330-841f-056e470bd0c5
begin
	Tᴺᵃ_b = 882.940u"°C"
	kᴺᵃ_F = 142u"W/(m*K)"
	kᶠᵉ_F = 80.4u"W/(m*K)"
	kᵁ_F = 27.5u"W/(m*K)"
end;

# ╔═╡ f7af01e7-68fd-4a99-85f4-43281a9ac114
begin
	cᴺᵃ_p = 28.230u"J/(mol*K)"/M_Na
	ν_Na = 0.5u"cSt"
end

# ╔═╡ eecb3f61-992b-4676-9eda-3b851280186c
begin
	Fᴺ_P = peakingfactor
	@handcalcs begin
		p̄_f = P_f / V_Core
		pᵐᵃˣ_f = Fᴺ_P * p̄_f
		A_F = N_FE * π * (d_fe/2)^2
		qᵐᵃˣp = pᵐᵃˣ_f * A_F
		q̃ppp = P_f / V_Core
	end
end

# ╔═╡ f6634678-3b27-480b-8a37-f701f083aed3
md"""
## Coolant requirements

Power peaking factor:

$$F_P^N = \frac{p_f^{(max)}}{\bar p_f}$$

``F_P^N`` = $peakingfactor

``\bar p_f`` = $(round(unit(p̄_f), p̄_f, sigdigits=4))

(p. 755)

Several factors must be calculated:

1. Results of the thermal core evaluation (inlet, outlet, average (bulk) in-core coolant temperatures for the hottest channel and for the average channel, in-core mass flow rate, max fuel centerline temperature). Discuss your results.
"""

# ╔═╡ dcfa6ff1-03c3-4b8e-9840-b15d46b5eb29
md"""
Dittus-Boelter Equation is applicable for Re>10,000Re>10,000 and 0.7<Pr<1600.7<Pr<160.
"""

# ╔═╡ 1b0ba15f-ecc8-47b1-80ad-2ac509520bfe
md"""
Bulk coolant temperature
"""

# ╔═╡ 4efdfde2-341f-420a-9164-66ebe1efe228
md"""
Fuel outer surface temperature
"""

# ╔═╡ 65963677-f6fa-46d7-95c0-c61669a4f172
md"""
Fuel centerline temperature
"""

# ╔═╡ 72fceafd-8339-47c6-a6a5-2a666760c885
md"""
## Requirements
1. The 8-group set of homogenized cross-sections representing the reactor core
"""

# ╔═╡ 80b0a8f0-e43b-4b13-8ce7-1f26cc976abf
Markdown.parse(create_markdown_table(round.(ustrip.(Σ_tr), digits=5), round.(ustrip.(Σ_γ), digits=5), round.(ustrip.(Σ_sr), digits=5), round.(ustrip.(Σ_f), digits=5); headers=["Σₜᵣ (1/cm)", "Σᵧ (1/cm)", "Σₛᵣ (1/cm)", "Σ_f (1/cm)"]))

# ╔═╡ 17f4db53-b258-44a0-ad03-6c7c2da4e8c4
md"""
2. Plot of the actual energy flux normalized to the specified power level
"""

# ╔═╡ 541f2176-66c5-4ce1-9d3a-b056fa158a84
ϕ_versus_energy

# ╔═╡ b8941cb6-e384-438b-a751-c1b6b0004d55
md"""
3. Estimated number of fuel elements in the core
The number of fuel elements was calculated based on the fuel element pitch. The area of the circular cross-section of the reactor was converted to the equvalent area square, and the side length was found. The number of elements needed to fill the square with a pitch of $p_fuel  was found. A value of ``N_{FE} =`` $N_FE allows for a value of ``V_{Cell} =`` $(round(typeof(1.0u"cm^3"), V_Cell, digits=3)) and ``V_M = `` $(round(typeof(1.0u"cm^3"), V_M, digits=3)), compared to ``V_{FE} = `` $(round(typeof(1.0u"cm^3"), V_FE, digits=3)).
"""

# ╔═╡ 2065153f-78f7-4e96-926c-aecb9d0c5eed
md"""
4. Plot of ``k_{eff}`` as a function of U-235 content in the core
"""

# ╔═╡ 9334c95a-95a7-40f6-b5e1-f3c5d0e3b093
k_eff_versus_enrichment_plot

# ╔═╡ 844cd5a0-6862-4087-9cda-3907a8df3a92
md"""
5. Compute value of ``\delta k_{eff} / k_{eff}`` for ``\delta x / x =`` $δx_x 

The value of ``δk_{eff}/k_{eff}`` was found to be $(round(δk_eff_k_eff(x), digits=5)).
"""

# ╔═╡ f209f47e-97ce-4ccc-87b8-88720c5a6ed8
md"""
6. Compute value of ``\delta k_{eff} / k_{eff}`` as a function of fluctuations of core dimensions

A function was developed that recomputes the value of ``k_{eff}`` for a dimension fluctuation in the core height and diameter. An example useage is for a fluctuation of 10 cm, the value of ``\delta k_{eff} / k_{eff}`` is $(round(k_eff_dimension_fluctuation(10u"cm"), digits = 5)).
"""

# ╔═╡ 28611530-faa5-44ba-b167-3d5e83d71c27
k_eff_dimension_fluctuation_plot

# ╔═╡ 0f9d44af-0760-45af-b3bc-21b038344e0b
md"""
7. The required fraction of U-235 to provide ``k_{eff}`` = $k_eff_target

A value of __$(round(100*target_enrichment, digits=3)) % U-235__ was found to achieve a ``k_{eff}``
of $k_eff_target.
"""

# ╔═╡ 9a8ba421-ae5a-442c-884c-4685c5b9fa42
md"""
8. Total fuel loading of the core (kg) and the corresponding mass of U-235 (kg)

It was found that the total fuel mass in the core was $(round(typeof(1.0u"kg"), upreferred(m_U), sigdigits=54)), and the mass of U-235 was $(round(typeof(1.0u"kg"), upreferred(m_U235), sigdigits=4)) at an enrichment of $(round(target_enrichment * 100, sigdigits=5)).
"""

# ╔═╡ 37501db5-fb96-4f83-9d82-b5d95a562261
md"""
10. Plots of in-core temperature distributions – coolant, cladding, fuel temperatures for the hottest channel.
"""

# ╔═╡ 7afcb3b3-f626-40f8-9bb4-1a16a3695437
md"""
11. Summary table of your design parameters and the design overview.
"""

# ╔═╡ c4c6a1ef-00be-472e-8747-00415201c4fc
md"""

Some adjustable parameters are presented here. If you wish to change any other parameters, simply edit values that are defined throughout the document.

| Mass flow rate (kg/s) | Inlet Temperature (°C) | U-235 Enrichment |
| ------------- | ------------- | ------------- |
| $(@bind w Slider((1.0:10.0)u"kg/s", default=5u"kg/s")) | $(@bind T_in Slider((373.15:1073.15)u"K", default=200.0u"K")) | $x_slider |
"""

# ╔═╡ d73da35e-ec07-4b01-9973-449b4f6e2e99
begin
	@handcalcs begin
	A_Core = π * r_core^2
	A_FE = N_FE * π * (d_fe/2)^2
	v = w / ρ_Na / (A_Core - A_FE)
	
	Re = v * d_fe / ν_Na
	μ_Na = ν_Na * ρ_Na
	Pr = μ_Na * cᴺᵃ_p / kᴺᵃ_F
	end
	if Re > 10000
		Nu = 0.023 * upreferred(Re)^0.8 * upreferred(Pr)^0.4
	else
		Nu = 3.66
	end
end

# ╔═╡ b9ee4f7b-df79-44b2-a6ef-47cd1b2cacd6
upreferred(Nu)

# ╔═╡ 69e4f542-5370-45b7-97e5-40feee8d5a4b
upreferred(Pr)

# ╔═╡ 4a13902f-8f3d-4dfd-998c-397585d5634a
begin
	h = Nu * kᴺᵃ_F / (d_fe/2)
end

# ╔═╡ cf577976-99b8-41c7-ba95-1e09d02c2169
ΔT_FE = 1 / (4π*kᵁ_F) + 1/(2π*kᶠᵉ_F)*log(d_fe / d_f) + (1 / (2*π*(d_fe/2) * h))

# ╔═╡ 74c22cee-8a90-4f7e-8cf0-76599d69f8e7
T_b(z) = T_in + (qᵐᵃˣp / (w*cᴺᵃ_p))*((h_extr) / π)*(sin(π/h_extr * z) + sin(π / (2*h_extr) * h_core))

# ╔═╡ ab90f84b-2efb-408a-908f-188ab9f1824b
T_out = T_b(h_core)

# ╔═╡ cf26d820-1ea0-41f7-9e95-466d401444c4
T_avg = (T_in + T_out)/2

# ╔═╡ e80e1cef-2e83-4793-88ed-71bc1f66efbb
T_FO(z) = T_in + qᵐᵃˣp * (h_extr / (π * w * cᴺᵃ_p) * (sin(π*z/h_extr)+sin(π*h_core / (2*h_extr))))

# ╔═╡ 05c44af1-64b3-444a-a8ca-dd723a8756ac
T_C(z) = T_in = qᵐᵃˣp * (h_extr / (π * w * cᴺᵃ_p) * (sin(π * z / h_extr) + sin(π * h_core / (2 * h_extr))) + ΔT_FE*cos(π * z / h_extr))

# ╔═╡ a95d29e3-0c7c-4b46-a648-5a9748bfac39
T_CO(z) = T_in + qᵐᵃˣp * (h_extr / (π * w * cᴺᵃ_p) * (sin(π/h_extr*z) + sin(π/(2*h_extr)*h_core)) + 1/(2π*(d_fe/2)*h) * cos(π / h_extr * z))

# ╔═╡ b01668ea-71a1-4adc-9dc9-796fe66167d3
T_CO(1u"cm")

# ╔═╡ fdcd3444-a994-4e87-8129-6778e912b1e9
coolant_temp_plot = let
	zs = range(-h_core/2, h_core/2, 1000)
	Ts = peakingfactor*T_b.(zs)
	Tos = peakingfactor*T_FO.(zs)
	Tcs = peakingfactor*upreferred.(T_C.(zs))
	Tcos = peakingfactor*upreferred.(T_CO.(zs))
	fig = Plot(Layout(
		height = 700, 
		title="Coolant and fuel (outer and centerline) temperature vs. height",
        xaxis=attr(
            title="Axial position ($(unit(zs[1])))", 
            gridcolor="lightgray",
			tickformat = "h",
        ),
		yaxis = attr(
            title = "Coolant bulk temperature ($(unit(Ts[1])))",
            gridcolor = "lightgray",
        ),
        template="simple_white",
		automargin=true,
		legend=attr(x=0.01, y=0.99,bgcolor="rgba(255,255,255,0.5)",bordercolor="gray")
	))

    add_trace!(fig, scatter(
        x=ustrip.(zs), 
        y=ustrip.(Ts),
        mode="line",
		name = "Coolant Temperature",
		showlegend = true,
    ))

	add_trace!(fig, scatter(
        x=ustrip.(zs), 
        y=ustrip.(Tos),
        mode="line",
		name = "Fuel Surface Temperature",
		line=attr(color="red", width=2, dash="dash"),
		showlegend = true,
    ))

	add_trace!(fig, scatter(
        x=ustrip.(zs), 
        y=ustrip.(Tcs),
        mode="line",
		name = "Fuel Centerline Temperature",
		# line=attr(color="red", width=2, dash="dash"),
		showlegend = true,
    ))

	add_trace!(fig, scatter(
        x=ustrip.(zs), 
        y=ustrip.(Tcos),
        mode="line",
		name = "Cladding Temperature",
		# line=attr(color="red", width=2, dash="dash"),
		showlegend = true,
    ))
	
	fig
end

# ╔═╡ c1d59fa0-94bf-4515-827e-73e7cc624369
coolant_temp_plot

# ╔═╡ 5fd0168e-9008-4ca1-8a90-dfc3c208f4e3
md"""
9. Results of the thermal core evaluation (inlet, outlet, average (bulk) in-core coolant temperatures for the hottest channel and for the average channel, in-core mass flow rate, max fuel centerline temperature). Discuss your results.

The inlet temperature was chosen at $T_in, and the flow rate was chosen at $w. These parameters ensured that the sodium was hot enough to not freeze, and that flow was high enough to allow the sodium to not boil.

The average temperature in the bulk was $T_avg, the coolant temperature maximum was $(T_out * peakingfactor), and the max centerline temperature was $(upreferred(T_C(0u"cm")) * peakingfactor). This is concerning as this is hotter than the melting point of uranium metal. Smaller fuel elements are likely required.

"""

# ╔═╡ 9f36e98f-ce51-42b8-9d34-a193a0f4d28a
md"""
| Mass flow rate (kg/s) | Inlet Temperature (°C) | Output Temperature (°C) | Enrichment | ``k_{eff}``
| ------------- | ------------- |  ------------- | ------------- | ------------- |
| $w | $T_in | $T_out |$k_eff | $enrichment |
"""

# ╔═╡ 4e2e7d80-49c7-4553-925b-34fc4fa56ae4
md"""
12. **Extra credit (50 points)** – results of your MCNP depletion analysis including core lifetime, fresh core energy distribution (spectrum) and reactivity coefficients (fuel and sodium), minimum enrichment value that yields $operationtime for the core lifetime and the corresponding BOL ``k_{eff}``. Discussion of your feasibility analysis of operating this reactor for $operationtime and how this fits with your selected reactor deployment application.
"""

# ╔═╡ 99996306-8ecf-449d-9805-d9673924897b
# TODO

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
FunctionZeros = "b21f74c0-b399-568f-9643-d20f4fa2c814"
Handcalcs = "e8a07092-c156-4455-ab8e-ed8bc81edefb"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Luxor = "ae8d54c2-7ccd-5906-9d76-62fc9837b5bc"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
PhysicalConstants = "5ad8b20f-a522-5ce9-bfc9-ddf1d5bda6ab"
PlutoExtras = "ed5d0301-4775-4676-b788-cf71e66ff8ed"
PlutoPlotly = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Roots = "f2b01f46-fcfa-551c-844a-d8ac1e96c665"
SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"
Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"
UnitfulLatexify = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"

[compat]
Colors = "~0.13.0"
DataFrames = "~1.7.0"
FunctionZeros = "~1.0.0"
Handcalcs = "~0.5.0"
LaTeXStrings = "~1.4.0"
Luxor = "~4.2.0"
Measurements = "~2.12.0"
PhysicalConstants = "~0.2.3"
PlutoExtras = "~0.7.15"
PlutoPlotly = "~0.3.4"
PlutoUI = "~0.7.61"
Roots = "~2.2.4"
SpecialFunctions = "~2.5.1"
Unitful = "~1.22.0"
UnitfulLatexify = "~1.6.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "8c4bd1d0608479c8bd554b37a6bff2addc222baf"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "MacroTools"]
git-tree-sha1 = "3b86719127f50670efe356bc11073d84b4ed7a5d"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.42"

    [deps.Accessors.extensions]
    AxisKeysExt = "AxisKeys"
    IntervalSetsExt = "IntervalSets"
    LinearAlgebraExt = "LinearAlgebra"
    StaticArraysExt = "StaticArrays"
    StructArraysExt = "StructArrays"
    TestExt = "Test"
    UnitfulExt = "Unitful"

    [deps.Accessors.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "71aa551c5c33f1a4415867fe06b7844faadb0ae9"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.1.1"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "2ac646d71d0d24b44f3f8c84da8c9f4d70fb67df"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.4+0"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9cb23bbb1127eefb022b022481466c0f1127d430"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.2"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "062c5e1a5bf6ada13db96a4ae4749a4c2234f521"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.3.9"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "403f2d8e209681fcbd9468a8514efff3ea08452e"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.29.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "64e15186f0aa277e174aa81798f7eb8598e0157e"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.0"

[[deps.CommonSolve]]
git-tree-sha1 = "0eee5eb66b1cf62cd6ad1b460238e60e4b09400c"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.4"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ConstructionBase]]
git-tree-sha1 = "76219f1ed5771adbb096743bff43fb5fdd4c1157"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.8"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "fb61b4812c49343d7ef0b533ba982c46021938a6"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.7.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4e1fe97fdaed23e9dc21d4d664bea76b65fc50a0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.22"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DocStringExtensions]]
git-tree-sha1 = "e7b7e6f178525d17c720ab9c081e4ef04429f860"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.4"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d55dffd9ae73ff72f1c0482454dcf2ec6c6c4a63"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.5+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "53ebe7511fa11d33bec688a9178fac4e49eeee00"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.2"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "b66970a70db13f45b7e57fbda1736e1cf72174ea"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.17.0"

    [deps.FileIO.extensions]
    HTTPExt = "HTTP"

    [deps.FileIO.weakdeps]
    HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "301b5d5d731a0654825f1f2e906990f7141a106b"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.16.0+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "2c5512e11c791d1baed2049c5652441b28fc6a31"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7a214fdac5ed5f59a22c2d9a885a16da1c74bbc7"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.17+0"

[[deps.FunctionZeros]]
deps = ["Roots", "SpecialFunctions"]
git-tree-sha1 = "0acddff2143204e318186edda996fa8615e1cabc"
uuid = "b21f74c0-b399-568f-9643-d20f4fa2c814"
version = "1.0.0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "b0036b392358c80d2d2124746c2bf3d48d457938"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.82.4+0"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "a641238db938fff9b2f60d08ed9030387daf428c"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.3"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a6dbda1fd736d60cc477d99f2e7a042acfa46e8"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.15+0"

[[deps.Handcalcs]]
deps = ["AbstractTrees", "CodeTracking", "InteractiveUtils", "LaTeXStrings", "Latexify", "MacroTools", "PrecompileTools", "Revise", "TestHandcalcFunctions"]
git-tree-sha1 = "1bb18c94645287fa0c499da38a6f04f74ef8f66d"
uuid = "e8a07092-c156-4455-ab8e-ed8bc81edefb"
version = "0.5.0"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "55c53be97790242c29031e5cd45e8ac296dadda3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.5.0+0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InlineStrings]]
git-tree-sha1 = "6a9fde685a7ac1eb3495f8e812c5a7c3711c2d5e"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.3"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"
    ParsersExt = "Parsers"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
    Parsers = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.InvertedIndices]]
git-tree-sha1 = "6da3c4316095de0f5ee2ebd875df8721e7e0bdbe"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.1"

[[deps.IrrationalConstants]]
git-tree-sha1 = "e2222959fbc6c19554dc15174c81bf7bf3aa691c"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.4"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eac1206917768cb54957c65a615460d87b455fc1"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.1+0"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "872cd273cb995ed873c58f196659e32f11f31543"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.44"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aaafe88dccbd957a8d82f7d05be9b69172e0cee3"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.0.1+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "78211fb6cbc872f77cad3fc0b6cf647d923f4929"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c602b1127f4751facb671441ca72715cc95938a"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.3+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "cd714447457c660382fe634710fb56eb255ee42e"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.6"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "27ecae93dd25ee0909666e6835051dd684cc035e"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+2"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a31572773ac1b745e0343fe5e2c8ddda7a37e997"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.41.0+0"

[[deps.Librsvg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pango_jll", "Pkg", "gdk_pixbuf_jll"]
git-tree-sha1 = "ae0923dab7324e6bc980834f709c4cd83dd797ed"
uuid = "925c91fb-5dd6-59dd-8e8c-345e74382d89"
version = "2.54.5+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "4ab7581296671007fc33f07a721631b8855f4b1d"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.1+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "321ccef73a96ba828cd51f2ab5b9f917fa73945a"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.41.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "31c1bff413ef2e8ed588564d994971eda2b311d6"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "3.2.1"

[[deps.Luxor]]
deps = ["Base64", "Cairo", "Colors", "DataStructures", "Dates", "FFMPEG", "FileIO", "PolygonAlgorithms", "PrecompileTools", "Random", "Rsvg"]
git-tree-sha1 = "9234dbf7598ba767b9c380c86104faa37187ab95"
uuid = "ae8d54c2-7ccd-5906-9d76-62fc9837b5bc"
version = "4.2.0"

    [deps.Luxor.extensions]
    LuxorExtLatex = ["LaTeXStrings", "MathTeXEngine"]

    [deps.Luxor.weakdeps]
    LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
    MathTeXEngine = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Measurements]]
deps = ["Calculus", "LinearAlgebra", "Printf"]
git-tree-sha1 = "3019b28107f63ee881f5883da916dd9b6aa294c1"
uuid = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
version = "2.12.0"

    [deps.Measurements.extensions]
    MeasurementsBaseTypeExt = "BaseType"
    MeasurementsJunoExt = "Juno"
    MeasurementsMakieExt = "Makie"
    MeasurementsRecipesBaseExt = "RecipesBase"
    MeasurementsSpecialFunctionsExt = "SpecialFunctions"
    MeasurementsUnitfulExt = "Unitful"

    [deps.Measurements.weakdeps]
    BaseType = "7fbed51b-1ef5-4d67-9085-a4a9b26f478c"
    Juno = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "9b8215b1ee9e78a293f99797cd31375471b2bcae"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.3"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.5+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a9697f1d06cc3eb3fb3ad49cc67f2cfabaac31ea"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.16+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6703a85cb3781bd5909d48730a67205f3f31a575"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.3+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3b31172c032a1def20c98dae3f2cdc9d10e3b561"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.56.1+0"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "44f6c1f38f77cafef9450ff93946c53bd9ca16ff"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.2"

[[deps.PhysicalConstants]]
deps = ["Measurements", "Roots", "Unitful"]
git-tree-sha1 = "cd4da9d1890bc2204b08fe95ebafa55e9366ae4e"
uuid = "5ad8b20f-a522-5ce9-bfc9-ddf1d5bda6ab"
version = "0.2.3"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "db76b1ecd5e9715f3d043cec13b2ec93ce015d53"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.44.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlotlyBase]]
deps = ["ColorSchemes", "Colors", "Dates", "DelimitedFiles", "DocStringExtensions", "JSON", "LaTeXStrings", "Logging", "Parameters", "Pkg", "REPL", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "90af5c9238c1b3b25421f1fdfffd1e8fca7a7133"
uuid = "a03496cd-edff-5a9b-9e67-9cda94a718b5"
version = "0.8.20"

    [deps.PlotlyBase.extensions]
    DataFramesExt = "DataFrames"
    DistributionsExt = "Distributions"
    IJuliaExt = "IJulia"
    JSON3Ext = "JSON3"

    [deps.PlotlyBase.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"

[[deps.PlutoExtras]]
deps = ["AbstractPlutoDingetjes", "DocStringExtensions", "HypertextLiteral", "InteractiveUtils", "Markdown", "PlutoUI", "REPL", "Random"]
git-tree-sha1 = "91d3820f5910572fd9c6077f177ba375e06f7a0e"
uuid = "ed5d0301-4775-4676-b788-cf71e66ff8ed"
version = "0.7.15"

[[deps.PlutoPlotly]]
deps = ["AbstractPlutoDingetjes", "Dates", "HypertextLiteral", "InteractiveUtils", "LaTeXStrings", "Markdown", "PlotlyBase", "PlutoUI", "Reexport"]
git-tree-sha1 = "b470931aa2a8112c8b08e66ea096c6c62c60571e"
uuid = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"
version = "0.3.4"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "7e71a55b87222942f0f9337be62e26b1f103d3e4"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.61"

[[deps.PolygonAlgorithms]]
git-tree-sha1 = "384967bb9b0dda05f9621e57c780dae5ca0c8574"
uuid = "32a0d02f-32d9-4438-b5ed-3a2932b48f96"
version = "0.3.2"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "1101cd475833706e4d0e7b122218257178f48f34"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.Revise]]
deps = ["CodeTracking", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "228d7dacca4558c8e522571da485c95fdfc3b1e3"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.7.4"

    [deps.Revise.extensions]
    DistributedExt = "Distributed"

    [deps.Revise.weakdeps]
    Distributed = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Roots]]
deps = ["Accessors", "CommonSolve", "Printf"]
git-tree-sha1 = "f233e0a3de30a6eed170b8e1be0440f732fdf456"
uuid = "f2b01f46-fcfa-551c-844a-d8ac1e96c665"
version = "2.2.4"

    [deps.Roots.extensions]
    RootsChainRulesCoreExt = "ChainRulesCore"
    RootsForwardDiffExt = "ForwardDiff"
    RootsIntervalRootFindingExt = "IntervalRootFinding"
    RootsSymPyExt = "SymPy"
    RootsSymPyPythonCallExt = "SymPyPythonCall"

    [deps.Roots.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalRootFinding = "d2bf35a9-74e0-55ec-b149-d360ff49b807"
    SymPy = "24249f21-da20-56a4-8eb1-6a02cf4ae2e6"
    SymPyPythonCall = "bc8888f7-b21e-4b7c-a06a-5d9c9496438c"

[[deps.Rsvg]]
deps = ["Cairo", "Glib_jll", "Librsvg_jll"]
git-tree-sha1 = "3d3dc66eb46568fb3a5259034bfc752a0eb0c686"
uuid = "c4c386cf-5103-5370-be45-f3a111cca3b8"
version = "1.0.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "712fb0231ee6f9120e005ccd56297abbc053e7e0"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.8"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "41852b8679f78c8d8961eeadc8f62cef861a52e3"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.5.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "725421ae8e530ec29bcbdddbe91ff8053421d023"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.1"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TestHandcalcFunctions]]
git-tree-sha1 = "54dac4d0a0cd2fc20ceb72e0635ee3c74b24b840"
uuid = "6ba57fb7-81df-4b24-8e8e-a3885b6fcae7"
version = "0.2.4"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.URIs]]
git-tree-sha1 = "cbbebadbcc76c5ca1cc4b4f3b0614b3e603b5000"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "c0667a8e676c53d390a09dc6870b3d8d6650e2bf"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.22.0"
weakdeps = ["ConstructionBase", "InverseFunctions"]

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "975c354fcd5f7e1ddcc1f1a23e6e091d99e99bc8"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.4"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "b8b243e47228b4a3877f1dd6aee0c5d56db7fcf4"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.6+1"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fee71455b0aaa3440dfdd54a9a36ccef829be7d4"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.1+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "b5899b25d17bf1889d25906fb9deed5da0c15b3b"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.12+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aa1261ebbac3ccc8d16558ae6799524c450ed16b"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.13+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "52858d64353db33a56e13c341d7bf44cd0d7b309"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.6+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "a4c0ee07ad36bf8bbce1c3bb52d21fb1e0b987fb"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.7+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "7ed9347888fac59a618302ee38216dd0379c480d"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.12+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXau_jll", "Xorg_libXdmcp_jll"]
git-tree-sha1 = "bfcaf7ec088eaba362093393fe11aa141fa15422"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.1+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a63799ff68005991f9d9491b6e95bd3478d783cb"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.6.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "446b23e73536f84e8037f5dce465e92275f6a308"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.gdk_pixbuf_jll]]
deps = ["Artifacts", "Glib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Xorg_libX11_jll", "libpng_jll"]
git-tree-sha1 = "cc803af2e0d7647ae880e7eaf4be491094def6c7"
uuid = "da03df04-f53b-5353-a52f-6a8b0620ced0"
version = "2.42.12+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "522c1df09d05a71785765d19c9524661234738e9"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.11.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e17c115d55c5fbb7e52ebedb427a0dca79d4484e"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a22cf860a7d27e4f3498a0fe0811a7957badb38"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.3+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "068dfe202b0a05b8332f1e8e6b4080684b9c7700"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.47+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "490376214c4721cdaca654041f635213c6165cb3"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+2"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"
"""

# ╔═╡ Cell order:
# ╠═f7d3d06a-1ec5-11f0-2bd5-39f3f59761b6
# ╠═1c367766-8fcf-46ee-89a8-ef7065f7e101
# ╟─e5dc3d5e-3748-460b-9ad7-ecb591cba7ad
# ╟─e00d6872-032c-4ef9-8793-8b95138c47b4
# ╟─aef066bc-294b-4464-aedd-2f9039f68ca2
# ╟─2940ea19-cd89-455a-8792-2f48d7790b40
# ╟─91ba4b60-c65d-41af-b293-5248c14b6cce
# ╟─043779a5-5e64-48cb-b5a6-1eaf401f3019
# ╟─cc03f841-80b8-481b-8b7c-0674e9aa35ed
# ╟─fb41b04b-0ffb-4686-915d-84f846820e4b
# ╟─9debb5ed-18cd-4252-a5e2-3c81833d9d6d
# ╟─48959bc2-8051-4a16-b6b4-85d208703207
# ╟─ebb5a02c-bed2-4005-905d-d74476abe85c
# ╟─ed80858a-5297-42dd-8a05-472897c675dc
# ╠═1f47fc1f-7a16-4156-ac06-0543d5866121
# ╠═4c77a865-46d7-4cee-974e-ad6177ac5435
# ╠═40af7228-e163-4d0f-8cd3-f20389558e64
# ╠═fb7d0c7a-21ce-4390-b3c3-9860184f5ab1
# ╠═7dcd34eb-3651-4d1a-9516-dba9ba5617d8
# ╠═c994fcf1-e8a2-433c-8c52-6f018d35b844
# ╠═18370f53-bb76-4a97-a314-1b941d848bc3
# ╠═796f5e11-c68c-454b-beb8-2630a909dd5c
# ╟─21879b35-ef24-478c-a8a4-a60f3a882804
# ╠═940921b5-c0cb-4841-b6ee-2f0d9de20d98
# ╠═9b4827d8-209c-444c-990e-a877669062d0
# ╟─651bbcdc-7495-4899-b8d4-9627060eba22
# ╠═7e0408f9-b69a-409f-9a5e-19bf0d543f66
# ╟─086e0d46-db87-4cdc-9d34-4056e0587450
# ╟─4bab2fa5-6b1b-4c9d-b8e4-e7cbcf085c84
# ╠═070e2f85-b2a2-4ef8-a9ba-f8960aa5cd51
# ╠═8d1dfed1-64ce-41be-9fa9-1f7e827879ef
# ╠═a5aa28d1-6149-40e4-bfd9-c3d02484f639
# ╠═de303102-9a99-44ca-b58d-99b677095ab1
# ╠═82d3a3cb-893a-4590-bbd4-aa432edca788
# ╠═89b877cd-615a-4fab-89a8-ae8f7a46a969
# ╠═e7900188-612e-4d7d-87e6-a5a87fafb496
# ╟─ea345c72-25bf-42f2-bf7e-6740876559f9
# ╟─cc534d9d-7e75-4d3e-96eb-461c39880349
# ╟─f6155a08-bf20-4635-bc75-13c3ec446728
# ╠═61a5bddd-7560-450e-80d2-19f1ca391d68
# ╟─8968d66b-ae18-4527-bcf6-0bc0d255d4b0
# ╠═36161f25-7fd2-4d74-9d70-918ac68f9563
# ╠═0e99355d-b149-4641-b69e-611effa644b0
# ╟─6d5bc584-3774-4df6-a15a-446263a943e2
# ╠═eff59af2-a578-4a9d-ab6b-1aae868eaa23
# ╟─87029787-4d53-4f59-9eba-50146f968832
# ╠═4df4c616-7f94-4e44-a003-a3d336429e66
# ╠═941ee37e-0e43-44a6-ae7f-727577a9817e
# ╠═8e9ca7e9-f75f-476e-93fb-09fe84db723a
# ╠═bc356317-fc2c-480b-b716-b90f0ff78096
# ╟─b0e1454f-f8a4-4540-972a-c78abee4e505
# ╠═9098e727-ad74-436b-a53f-36e7e2c37518
# ╟─3132ebbd-2fc4-4b58-9cbb-34f8e9715c78
# ╠═3bf956b6-f767-44d5-9135-046171215790
# ╟─b594117a-c70d-4486-94a2-4990bf145e1e
# ╟─7b8edcf9-de43-4ece-aaae-8c9b88d846fc
# ╠═2a1b3028-d3ec-4762-92e9-be038e28062a
# ╠═24321c2b-3302-4823-9f6a-fd712dbab041
# ╠═16b9dd3f-6eaf-4390-ada2-21a3a1c0dc4d
# ╠═bf17d087-6ef2-4384-9f77-be401705dc27
# ╠═10fdf51d-57bc-4b86-9c03-dd6d331068b2
# ╠═bfc91e5d-de00-437d-a5f4-75e48b4d945a
# ╟─6917cc86-7849-425e-bcc0-77b4efa30115
# ╟─4678c34f-7fbb-41f0-9874-3bf8296b3df6
# ╠═cc1ef5a4-2ab8-444b-8631-05983ac0f30f
# ╟─72dd6efd-5129-4a2f-86b5-65145157d5fc
# ╠═b1adf867-f820-4079-bdea-653969b91d58
# ╠═1b24ba31-fc23-4a10-b950-c15c74c012fd
# ╠═f6634678-3b27-480b-8a37-f701f083aed3
# ╠═3f282d1a-55ee-4f39-b554-513bcfa3db0c
# ╠═36e07c28-4722-4330-841f-056e470bd0c5
# ╠═f7af01e7-68fd-4a99-85f4-43281a9ac114
# ╠═eecb3f61-992b-4676-9eda-3b851280186c
# ╠═dcfa6ff1-03c3-4b8e-9840-b15d46b5eb29
# ╠═d73da35e-ec07-4b01-9973-449b4f6e2e99
# ╠═b9ee4f7b-df79-44b2-a6ef-47cd1b2cacd6
# ╠═69e4f542-5370-45b7-97e5-40feee8d5a4b
# ╟─1b0ba15f-ecc8-47b1-80ad-2ac509520bfe
# ╠═74c22cee-8a90-4f7e-8cf0-76599d69f8e7
# ╠═ab90f84b-2efb-408a-908f-188ab9f1824b
# ╠═cf26d820-1ea0-41f7-9e95-466d401444c4
# ╟─4efdfde2-341f-420a-9164-66ebe1efe228
# ╠═e80e1cef-2e83-4793-88ed-71bc1f66efbb
# ╠═4a13902f-8f3d-4dfd-998c-397585d5634a
# ╠═cf577976-99b8-41c7-ba95-1e09d02c2169
# ╟─65963677-f6fa-46d7-95c0-c61669a4f172
# ╠═05c44af1-64b3-444a-a8ca-dd723a8756ac
# ╠═a95d29e3-0c7c-4b46-a648-5a9748bfac39
# ╠═b01668ea-71a1-4adc-9dc9-796fe66167d3
# ╠═fdcd3444-a994-4e87-8129-6778e912b1e9
# ╟─72fceafd-8339-47c6-a6a5-2a666760c885
# ╟─80b0a8f0-e43b-4b13-8ce7-1f26cc976abf
# ╟─17f4db53-b258-44a0-ad03-6c7c2da4e8c4
# ╟─541f2176-66c5-4ce1-9d3a-b056fa158a84
# ╟─b8941cb6-e384-438b-a751-c1b6b0004d55
# ╟─2065153f-78f7-4e96-926c-aecb9d0c5eed
# ╟─9334c95a-95a7-40f6-b5e1-f3c5d0e3b093
# ╟─844cd5a0-6862-4087-9cda-3907a8df3a92
# ╟─f209f47e-97ce-4ccc-87b8-88720c5a6ed8
# ╟─28611530-faa5-44ba-b167-3d5e83d71c27
# ╟─0f9d44af-0760-45af-b3bc-21b038344e0b
# ╟─9a8ba421-ae5a-442c-884c-4685c5b9fa42
# ╟─5fd0168e-9008-4ca1-8a90-dfc3c208f4e3
# ╟─37501db5-fb96-4f83-9d82-b5d95a562261
# ╠═c1d59fa0-94bf-4515-827e-73e7cc624369
# ╟─7afcb3b3-f626-40f8-9bb4-1a16a3695437
# ╟─c4c6a1ef-00be-472e-8747-00415201c4fc
# ╟─9f36e98f-ce51-42b8-9d34-a193a0f4d28a
# ╟─4e2e7d80-49c7-4553-925b-34fc4fa56ae4
# ╠═99996306-8ecf-449d-9805-d9673924897b
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
