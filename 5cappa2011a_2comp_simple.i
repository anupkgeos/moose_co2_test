# Problem description - isothermal case
[Mesh]
  [file_mesh]
    type = FileMeshGenerator
    file = 'cappa2011_simple.msh'
  []
[]

[GlobalParams]
  PorousFlowDictator = 'dictator'
  gravity = '0 -9.81 0'
[]

[AuxVariables]
  [xnacl]
    initial_condition = 0.01
  []
  [saturation_gas]
    order = CONSTANT
    family = MONOMIAL
  []
  [x1]
    order = CONSTANT
    family = MONOMIAL
  []
  [y0]
    order = CONSTANT
    family = MONOMIAL
  []
  [temperature0]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [temp]
    type = FunctionAux
    variable = temperature0
    function = 'temp_ic'
    execute_on = 'INITIAL'
  []
  [saturation_gas]
    type = PorousFlowPropertyAux
    variable = saturation_gas
    property = saturation
    phase = 1
    execute_on = 'timestep_end'
  []
  [x1]
    type = PorousFlowPropertyAux
    variable = x1
    property = mass_fraction
    phase = 0
    fluid_component = 1
    execute_on = 'timestep_end'
  []
  [y0]
    type = PorousFlowPropertyAux
    variable = y0
    property = mass_fraction
    phase = 1
    fluid_component = 0
    execute_on = 'timestep_end'
  []
[]

[Variables]
  [pgas]
    #scaling = 1E6
    [InitialCondition]
      type = FunctionIC
      function = 'p0'
    []
  []
  [zi]
    initial_condition = 0.0
    #scaling = 1e4
  []
[]
[ICs]
  [temperature_ic]
    type = FunctionIC
    function = 'temp_ic'
    variable = temperature0
  []
[]

[Kernels]
  [mass0]
    type = PorousFlowMassTimeDerivative
    fluid_component = 0
    variable = pgas
  []
  [mass1]
    type = PorousFlowMassTimeDerivative
    fluid_component = 1
    variable = zi
  []
  [flux0]
    type = PorousFlowAdvectiveFlux
    fluid_component = 0
    variable = pgas
  []
  [flux1]
    type = PorousFlowAdvectiveFlux
    fluid_component = 1
    variable = zi
  []
[]

[UserObjects]
  [dictator]
    type = PorousFlowDictator
    porous_flow_vars = 'pgas zi'
    number_fluid_phases = 2
    number_fluid_components = 2
  []
  [pc]

    type = PorousFlowCapillaryPressureConst
    pc = 0
  #   type = PorousFlowCapillaryPressureVG
  #   alpha = 5.099e-5 #1e1
  #   m = 0.457
  #   sat_lr = 0.0
  #   pc_max = 1e7
  []
  [fs]
    type = PorousFlowBrineCO2
    brine_fp = brine
    co2_fp = co2
    capillary_pressure = pc
  []
[]

[FluidProperties]
  [co2]
    type = CO2FluidProperties
  []
  # [co2]
  #   type = TabulatedFluidProperties
  #   fp = co2sw
  # []
  [water]
    type = Water97FluidProperties
  []
  # [watertab]
  #   type = TabulatedFluidProperties
  #   fp = water
  #   temperature_min = 273.15 # K
  #   temperature_max = 573.15 # K
  #   pressure_max = 5e+08
  #   fluid_property_file = water_fluid_properties.csv
  #   save_file = false
  # []
  [brine]
    type = BrineFluidProperties
    #water_fp = watertab
  []
[]

[Materials]
  [eff_fluid_pressure]
    type = PorousFlowEffectiveFluidPressure
  []
  [temperature]
    type = PorousFlowTemperature
    temperature = 'temperature0'
  []
  [brineco2]
    type = PorousFlowFluidState
    gas_porepressure = 'pgas'
    z = zi
    temperature_unit = Celsius
    xnacl = xnacl
    capillary_pressure = pc
    fluid_state = fs
  []
  [porosity_aquifer]
    type = PorousFlowPorosityConst
    block = 'aquifer'
    porosity = '0.1'
  []
  [porosity_cap]
    type = PorousFlowPorosityConst
    block = 'caps'
    porosity = '0.01'
  []
  [permeability_aquifer]
    type = PorousFlowPermeabilityConst
    block = 'aquifer'
    permeability = '1e-13 0 0 0 1e-13 0 0 0 1e-13'
  []
  [permeability_cap]
    type = PorousFlowPermeabilityConst
    block = 'caps'
    permeability = '1e-19 0 0 0 1e-19 0 0 0 1e-19'
  []
  [relperm_water]
    type = PorousFlowRelativePermeabilityCorey
    n = 4
    phase = 0
    s_res = 0.200
    sum_s_res = 0.405
  []
  [relperm_gas]
    type = PorousFlowRelativePermeabilityBC
    phase = 1
    s_res = 0.205
    sum_s_res = 0.405
    nw_phase = true
    lambda = 2
  []
[]

[BCs]
  # Left pgas = No flow
  [injection_area]
    type = PorousFlowSink
    boundary = injection_area
    variable = zi
    fluid_phase = 1 #gas phase
    flux_function = 'min(t/100.0,1)*(-0.2)' # kg/s/m
  []
  [top_pgas]
    type = DirichletBC
    variable = pgas
    value = 12.853e6  # # as per gradient
    boundary = 'top'
  []
  [top_zi]
    type = PorousFlowOutflowBC
    variable = zi
    boundary = 'top bottom right'
  []
  [bottom_pgas]
    type = DirichletBC
    variable = pgas
    value = 16.777e6  # as per gradient
    boundary = 'bottom'
  []
  [right_pgas]
    type = FunctionDirichletBC
    variable = pgas
    function = p0 # same as initial pressure gradient
    boundary = 'right'
  []
[]

[Preconditioning]
  [smp]
    type = SMP
    full = true
    petsc_options_iname = '-ksp_type -pc_type -sub_pc_type -sub_pc_factor_shift_type'
    petsc_options_value = 'gmres bjacobi lu NONZERO'
  []
[]



[Functions]
  [p0]
    type = ParsedFunction
    expression = '0.1e6 - 9.81e3 * y' # -ve y 9.81 MPa/km = 9.81e6/1000m = 9.81e3Pa/m
    execute_on = INITIAL
  []
  [temp_ic]
    type = ParsedFunction
    expression =  '10 - 25e-3 * y' # -ve y 25C/km = 25/1000m = 25e-3C/m
    execute_on = INITIAL
  []
[]



[Executioner]
  type = Transient
  solve_type = NEWTON
  end_time = 3456000
  nl_max_its = 25
  l_max_its = 10
  dtmax = 7200
  l_abs_tol = 1e-5
  nl_abs_tol = 1e-3
  automatic_scaling = true
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 10
  []
  dtmin = 1
[]

[Outputs]
  exodus = true
[]

[Postprocessors]
  [tempurate]
    type = FunctionValuePostprocessor
    function = temp_ic
    execute_on = INITIAL
  []
[]
