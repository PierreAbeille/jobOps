-- Nettoyage optionnel si tu relances
-- DELETE FROM enum_values;

-- remote_type
INSERT INTO enum_values(category, code, label, sort_order) VALUES
('remote_type','remote','Remote',1),
('remote_type','hybrid','Hybrid',2),
('remote_type','onsite','On-site',3)
ON CONFLICT DO NOTHING;

-- contract_type
INSERT INTO enum_values(category, code, label, sort_order) VALUES
('contract_type','freelance','Freelance',1),
('contract_type','cdi','CDI',2),
('contract_type','cdd','CDD',3),
('contract_type','contract','Contract',4),
('contract_type','internship','Internship',5),
('contract_type','part-time','Part-time',6)
ON CONFLICT DO NOTHING;

-- offer_contact_role
INSERT INTO enum_values(category, code, label, sort_order) VALUES
('offer_contact_role','poster','Poster',1),
('offer_contact_role','recruiter','Recruiter',2),
('offer_contact_role','hiring_manager','Hiring manager',3),
('offer_contact_role','tech_lead','Tech lead',4),
('offer_contact_role','referrer','Referrer',5),
('offer_contact_role','other','Other',9)
ON CONFLICT DO NOTHING;

-- thread_type
INSERT INTO enum_values(category, code, label, sort_order) VALUES
('thread_type','application','Application',1),
('thread_type','outreach','Outreach',2)
ON CONFLICT DO NOTHING;

-- thread_status
INSERT INTO enum_values(category, code, label, sort_order) VALUES
('thread_status','sent','Sent',1),
('thread_status','followup1','Follow-up 1',2),
('thread_status','followup2','Follow-up 2',3),
('thread_status','interview','Interview',4),
('thread_status','offer','Offer',5),
('thread_status','rejected','Rejected',6),
('thread_status','no_reply','No reply',7),
('thread_status','open','Open',8),
('thread_status','closed','Closed',9)
ON CONFLICT DO NOTHING;

-- channel
INSERT INTO enum_values(category, code, label, sort_order) VALUES
('channel','email','Email',1),
('channel','linkedin','LinkedIn',2),
('channel','portal','Portal',3),
('channel','phone','Phone',4),
('channel','other','Other',9)
ON CONFLICT DO NOTHING;

-- interaction_kind
INSERT INTO enum_values(category, code, label, sort_order) VALUES
('interaction_kind','email','Email',1),
('interaction_kind','call','Call',2),
('interaction_kind','dm','Direct message',3),
('interaction_kind','meeting','Meeting',4),
('interaction_kind','note','Note',5),
('interaction_kind','status_change','Status change',6),
('interaction_kind','webhook','Webhook',7)
ON CONFLICT DO NOTHING;

-- direction
INSERT INTO enum_values(category, code, label, sort_order) VALUES
('direction','in','Inbound',1),
('direction','out','Outbound',2),
('direction','n/a','N/A',3)
ON CONFLICT DO NOTHING;