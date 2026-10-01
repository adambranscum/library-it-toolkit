# Collapsed Core Architecture

A simpler network design for small and mid-size libraries.

*Cybersecurity on a Library Budget | github.com/adambranscum/library-it-toolkit*

*Questions? [abranscum@nlrlibrary.org](mailto:abranscum@nlrlibrary.org)*

## How It Works

### Collapsed Core (Two-Tier)

```
        [ CORE / DISTRIBUTION] <- one layer does both jobs
         /     |      |      \
   [ACCESS] [ACCESS] [ACCESS] [ACCESS]
```

The core switch (or a redundant pair) handles:

- **Routing** between VLANs (staff, public, phones, IT)
- **Uplinks** from every access switch
- **Policy**, such as which VLANs can talk to each other

Access switches only do what they do best: connect devices and pass traffic up.

## Why It Fits Libraries

Libraries usually have a few hundred ports per building, not thousands.

| Benefit | What It Means |
| --- | --- |
| **Lower cost** | Fewer switches to buy, power, and license. Older switches can be reused as access layer. |
| **Simpler troubleshooting** | Fewer hops means fewer places for a problem to hide. |
| **Faster traffic** | Traffic crosses fewer devices between any two points. |
| **Easier changes** | VLANs and routing rules live in one place, not spread across layers. |
| **Less rack space and power** | Fewer switches, less heat, less cabling. |
| **Easier to document** | A two-layer diagram is one a new staff member can understand. |

## Trade-Offs

|  |  |
| --- | --- |
| **Core is a single point of failure** | Use a redundant pair or a stacked/clustered switch if budget allows. Otherwise keep a spare and a current config backup. |
| **Limited growth** | Works well up to a few hundred ports per site. Past that, plan a third tier. |
| **Core needs enough capacity** | Choose a core with enough Layer 3 routing performance and uplink ports. |
| **More depends on one device** | Back up the config after every change. |

## Pair It with VLANs

A collapsed core is the natural place to separate traffic. Typical VLAN split:

- Staff
- Public
- Phones (VoIP)
- Staff Wi-Fi
- IT / management

Public traffic never touches staff resources. Voice traffic gets its own lane.

## Quick Build Checklist

1. Map every access switch and where its uplink goes.
2. Choose the core: enough ports, Layer 3 routing, room to grow.
3. Plan VLAN numbers and IP ranges **on paper first**.
4. Connect each access switch to the core with its own uplink.
5. Create VLANs and routing on the core.
6. Set firewall rules for which VLANs may reach which.
7. Cut over one site at a time, after hours.
8. Test staff, public, and phone traffic before opening.
9. Back up every switch config and store it off the device.
10. Update your network diagram.
