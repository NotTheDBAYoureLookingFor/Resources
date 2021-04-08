SELECT m.total_physical_memory_kb / 1024 / 1024.0 AS PhysicalMemory,
	   m.available_physical_memory_kb / 1024 / 1024.0 AS AvailableMemory 

FROM sys.dm_os_sys_memory m